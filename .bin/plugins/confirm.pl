#!/usr/bin/perl -w

#
#    Copyright (C) 2008~2014 SHIE, Li-Yi (lyshie) <lyshie@mx.nthu.edu.tw>
#
#    https://github.com/lyshie
#	
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation,  either version 3 of the License,  or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful, 
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not,  see <http://www.gnu.org/licenses/>.
#
use strict;
use warnings;
#
umask(0000);
#
# Shie, Li-Yi <lyshie@mx.nthu.edu.tw>
# 1. A moderate function for SmartList (replace flist)
#
use FindBin qw($Bin);
#
use Mail::Header;
use Mail::Internet;
use Mail::Address;
use MIME::Words qw(:all);
use File::Basename;
use File::Copy;
use Unix::Syslog qw(:macros :subs);
#
use lib "$Bin";
use ListUtils;
use ListLog;
use ListBounce;
#
my $LOGFILE     = "$Bin/log";
my $LISTNAME    = $ARGV[0] || die("Error: No listname\n");
$LISTNAME =~ s/\-request$//;
my $MAINTAINER  = getListMaintainer($LISTNAME);
my @MESSAGES    = ();
my @MSGS        = ();
my $MAIL_HEADER = undef;
my $MAIL_BODY   = undef;
my ($SUBJECT, $SUBJECT_CHARSET, $SUBJECT_ENCODING) =
   ('', 'UTF-8', 'B');
my $COMMAND     = '';
my $RAND_MAX    = 999999;
my $UID         = time() . int(rand($RAND_MAX));

my $SENDMAIL    = "/usr/sbin/sendmail -oi -f $LISTNAME-request\@" . getListDomain();
my $FLIST       = "$SMARTLIST_PATH/.bin/flist";
my $SENDER      = ();
my $XLOOP       = '';
#
sub commandSubscribe;
sub commandUnsubscribe;
sub commandInvalid;
sub commandUnknown;
sub getCommand;
sub parseCommand;
sub checkSender;
sub getMail;
sub commandAlreadySubscribe;
sub commandAlreadyUnsubscribe;

# lyshie: get the command and parameters from subject
sub getCommand
{
    my $subject = getDecodedSubject($MAIL_HEADER->get('subject'));
    chomp($subject);

    my ($command, $remainder) = ('', '');

    my @tokens = split(/\s+/, $subject);
    for (my $i = 0; $i < @tokens; $i++) {
        if (lc($tokens[$i]) eq 'unsubscribe') {
            $command = $tokens[$i];
            last;
        }
        if (lc($tokens[$i]) eq 'subscribe') {
            $command = $tokens[$i];
            last;
        }
        if (lc($tokens[$i]) eq 'confirm') {
            $command = $tokens[$i];
            $remainder = $tokens[$i+1] || '';;
            last;
        }
    }

    return (lc($command), $remainder);
}

sub commandConfirm
{
    my $param = shift;
    my $domain = getListDomain();
    my $email = '';

    my ($flag, $id) = ('', '');
    $param =~ m/(s|u)(\d+)/i;
    $flag = $1 || '';
    $flag = lc($flag);
    $id = $2 || '';

    my $path = "$SMARTLIST_PATH/$LISTNAME/confirm";

    return if (!-f "$path/$flag$id");
    open(FH, "$path/$flag$id");
    $email = <FH>;
    chomp($email);
    close(FH);

    my $action = '';
    if ($flag eq 's') {
        $action = 'subscribe';
    }
    elsif ($flag eq 'u') {
        $action = 'unsubscribe';
    }
    else {
        return;
    }

    open(FH, "|$FLIST $LISTNAME-request");
    # prevent mail loop
    #if ($XLOOP eq '') {
    #    print FH "X-Loop: $LISTNAME-request\@$domain\n";
    #}
    #else {
    #    print FH "X-Loop: $XLOOP\n";
    #}
    print FH <<EOF
From: $email
To: $LISTNAME-request\@$domain
Subject: $action

EOF
;
    close(FH);

    unlink("$path/$flag$id");

    if ($flag eq 's') {
        removeUnneeded($LISTNAME, [$email]);
    }
    elsif ($flag eq 'u') {
        addUnneeded($LISTNAME, [$email]);
    }

    syslog(LOG_INFO,
           "Action. (action=%s, listname=%s, email=%s)",
           $action,
           $LISTNAME,
           $email
          );

    logToList($LISTNAME,
              "[%s] ACTION (%s, %s)",
              basename($0),
              $action,
              $email
             );

    return 1;
}

sub commandAlreadySubscribe
{
    my $domain = getListDomain();

    my $file = "$Bin/confirm_already_subscribe.txt";
    my $subscribe_part = '';

    open(FH, "$file");
    while (<FH>) {
        $subscribe_part .= $_;
    }
    close(FH);

    $subscribe_part =~ s/#MAIL#/$SENDER/gm;
    $subscribe_part =~ s/#LISTNAME#/$LISTNAME/gm;
    my $ip = $MAIL_HEADER->get('x-ip-address') || "未知";
    $subscribe_part =~ s/#IP#/$ip/gm;

    open(FH, "|$SENDMAIL $SENDER");
    # prevent mail loop
    if ($XLOOP eq '') {
        print FH "X-Loop: $LISTNAME-request\@$domain\n";
    }
    else {
        print FH "X-Loop: $XLOOP\n";
    }
    print FH <<EOF
From: $LISTNAME-request\@$domain
To: $SENDER
Subject: [$LISTNAME] Already on the subscriber list
$subscribe_part
EOF
;
    close(FH);

    syslog(LOG_INFO,
           "Already on the subscriber list. (listname=%s, email=%s)",
           $LISTNAME,
           $SENDER
          );
}

# lyshie: subscribe
sub commandSubscribe
{
    my ($fixed, $auto) = getDists($LISTNAME);
    my @all = (@$auto);
    foreach (@all) {
        if ($_ eq $SENDER) {
            commandAlreadySubscribe();
            return;
        }
    }

    my $domain = getListDomain();

    my $path = "$SMARTLIST_PATH/$LISTNAME/confirm";
    mkdir($path) if (!-d $path);

    open(FH, ">$path/s$UID");
    print FH $SENDER;
    close(FH);

    my $file = "$Bin/confirm_subscribe.txt";
    my $subscribe_part = '';

    open(FH, "$file");
    while (<FH>) {
        $subscribe_part .= $_;
    }
    close(FH);

    $subscribe_part =~ s/#LISTNAME#/$LISTNAME/gm;
    my $ip = $MAIL_HEADER->get('x-ip-address') || "未知";
    $subscribe_part =~ s/#IP#/$ip/gm;

    open(FH, "|$SENDMAIL $SENDER");
    # prevent mail loop
    #if ($XLOOP eq '') {
    #    print FH "X-Loop: $LISTNAME-request\@$domain\n";
    #}
    #else {
    #    print FH "X-Loop: $XLOOP\n";
    #}
    print FH <<EOF
From: $LISTNAME-request\@$domain
To: $SENDER
Subject: [$LISTNAME] confirm s$UID
$subscribe_part
EOF
;
    close(FH);

    syslog(LOG_INFO,
           "Confirm to subscribe. (id=%s, listname=%s, email=%s)",
           $UID,
           $LISTNAME,
           $SENDER
          );
}

sub commandAlreadyUnsubscribe
{
    my $domain = getListDomain();

    my $file = "$Bin/confirm_already_unsubscribe.txt";
    my $unsubscribe_part = '';

    open(FH, "$file");
    while (<FH>) {
        $unsubscribe_part .= $_;
    }
    close(FH);

    $unsubscribe_part =~ s/#MAIL#/$SENDER/gm;
    $unsubscribe_part =~ s/#LISTNAME#/$LISTNAME/gm;
    my $ip = $MAIL_HEADER->get('x-ip-address') || "未知";
    $unsubscribe_part =~ s/#IP#/$ip/gm;

    open(FH, "|$SENDMAIL $SENDER");
    # prevent mail loop
    if ($XLOOP eq '') {
        print FH "X-Loop: $LISTNAME-request\@$domain\n";
    }
    else {
        print FH "X-Loop: $XLOOP\n";
    }
    print FH <<EOF
From: $LISTNAME-request\@$domain
To: $SENDER
Subject: [$LISTNAME] Your name is not on the list
$unsubscribe_part
EOF
;
    close(FH);

    syslog(LOG_INFO,
           "Your name is not on the list. (listname=%s, email=%s)",
           $LISTNAME,
           $SENDER
          );
}

# lyshie: unsubscribe
sub commandUnsubscribe
{
    my ($fixed, $auto) = getDists($LISTNAME);
    my @all = (@$auto);
    my $found = 0;
    foreach (@all) {
        if ($_ eq $SENDER) {
            $found = 1;
            last;
        }
    }
    return commandAlreadyUnsubscribe() if ($found == 0);

    my $domain = getListDomain();

    my $path = "$SMARTLIST_PATH/$LISTNAME/confirm";
    mkdir($path) if (!-d $path);

    open(FH, ">$path/u$UID");
    print FH $SENDER;
    close(FH);

    my $file = "$Bin/confirm_unsubscribe.txt";
    my $unsubscribe_part = '';

    open(FH, "$file");
    while (<FH>) {
        $unsubscribe_part .= $_;
    }
    close(FH);

    $unsubscribe_part =~ s/#LISTNAME#/$LISTNAME/gm;
    my $ip = $MAIL_HEADER->get('x-ip-address') || "未知";
    $unsubscribe_part =~ s/#IP#/$ip/gm;

    open(FH, "|$SENDMAIL $SENDER");
    # prevent mail loop
    #if ($XLOOP eq '') {
    #    print FH "X-Loop: $LISTNAME-request\@$domain\n";
    #}
    #else {
    #    print FH "X-Loop: $XLOOP\n";
    #}
    print FH <<EOF
From: $LISTNAME-request\@$domain
To: $SENDER
Subject: [$LISTNAME] confirm u$UID
$unsubscribe_part
EOF
;
    close(FH);

    syslog(LOG_INFO,
           "Confirm to unsubscribe. (id=%s, listname=%s, email=%s)",
           $UID,
           $LISTNAME,
           $SENDER
          );
}

sub commandInvalid
{
    my $command = shift;
    my $domain = getListDomain();

    my $subject = getDecodedSubject($MAIL_HEADER->get('subject'));
    chomp($subject);

    my $file = "$Bin/confirm_invalid.txt";
    my $invalid_part = '';

    open(FH, "$file");
    while (<FH>) {
        $invalid_part .= $_;
    }
    close(FH);

    $invalid_part =~ s/#COMMAND#/$subject/gm;

    open(FH, "|$SENDMAIL $SENDER");
    # prevent mail loop
    if ($XLOOP eq '') {
        print FH "X-Loop: $LISTNAME-request\@$domain\n";
    }
    else {
        print FH "X-Loop: $XLOOP\n";
    }
    print FH <<EOF
From: $LISTNAME-request\@$domain
To: $SENDER
Subject: [$LISTNAME] INVALID COMMAND
$invalid_part
EOF
;
    close(FH);

    syslog(LOG_INFO,
           "Invalid command. (listname=%s, subject=%s)",
           $LISTNAME,
           $subject
          );
}

sub commandUnknown
{
    my $domain = getListDomain();
    my $maintainer = getListMaintainer($LISTNAME);
    my $subject = getDecodedSubject($MAIL_HEADER->get('subject'));

    $MAIL_HEADER->replace('to', $maintainer);

    # prevent mail loop
    if ($XLOOP eq '') {
        $MAIL_HEADER->replace('x-loop', "$LISTNAME-request\@$domain");
    }
    else {
        $MAIL_HEADER->replace('x-loop', $XLOOP);
    }

    open(FH, "|$SENDMAIL $maintainer");
    print FH $MAIL_HEADER->as_string(), "\n";
    foreach (@$MAIL_BODY) {
        print FH "$_";
    }
    close(FH);

    syslog(LOG_INFO,
           "Unknown command. (listname=%s, maintainer=%s, subject=%s)",
           $LISTNAME,
           $maintainer,
           $subject
          );
}

# lyshie: parse the subject and check if it contains the command part
sub parseCommand
{
    # check mail loop
    $XLOOP = $MAIL_HEADER->get('x-loop') || '';
    chomp($XLOOP);

    if ($XLOOP eq "$LISTNAME-request\@" . getListDomain()) {
        syslog(LOG_INFO,
               "Mail loop detected, drop it. (listname=%s, xloop=%s)",
               $LISTNAME,
               $XLOOP,
              );
        return;
    }
    #

    my $valid = 0;
    ($valid, $SENDER) = checkSender();

    # lyshie_20080908: check mail bounce
    my $subject = $MAIL_HEADER->get('subject') || '';
    my @emails  = ();
    if (checkUndelivered($SENDER, $subject, '')) {
        @emails = extractMailAddress($MAIL_BODY);
        addToBounce($LISTNAME, \@emails); 
            open(FFH, ">>/usr/local/slist/tmp/undelivered");
            print FFH "----------------------------------------------------------\n";
            print FFH $MAIL_HEADER->as_string(), "\n";
            foreach (@$MAIL_BODY) {
            print FFH "$_";
            }
            close(FFH);
    }

    if (scalar(@emails) > 0) {
        $valid = 1;
    }
    else {
        $valid = 0;
    }

    # lyshie_20080908: check sender consistency
    # lyshie_20080908: if it is not an undelivered mail
    #if ($valid == 0) {
    #    commandInvalid();
    #    return;
    #}

    my $remainder = '';
    ($COMMAND, $remainder) = getCommand();

    if ($COMMAND eq 'unsubscribe') {
        commandUnsubscribe();
    }
    elsif ($COMMAND eq 'subscribe') {
        commandSubscribe();
    }
    elsif ($COMMAND eq 'confirm') {
        commandUnknown() unless commandConfirm($remainder);
    }
    else {
        commandUnknown();
    }
}

sub checkSender
{
    my @topfrom_addr =
        Mail::Address->parse($MAIL_HEADER->get('from '));
    my @returnpath_addr =
        Mail::Address->parse($MAIL_HEADER->get('return-path'));
    my @from_addr =
        Mail::Address->parse($MAIL_HEADER->get('from'));

    my ($topfrom, $returnpath, $from) = ('', '', '');
    if (@topfrom_addr > 0) {
        $topfrom = $topfrom_addr[0]->address() || '';
    }
    if (@returnpath_addr > 0) {
        $returnpath = $returnpath_addr[0]->address() || '';
    }
    if (@from_addr > 0) {
        $from = $from_addr[0]->address() || '';
    }

    if ($from eq '') {
        return (0, '');
    }

    if ($topfrom ne '') {
        if ($from ne $topfrom) {
            return (0, $topfrom);
        }
    }

    if ($returnpath ne '') {
        if ($from ne $returnpath) {
            return (0, $returnpath);
        }
    }

    return (1, $from);
}

# lyshie: read mail from STDIN and separate into head and body part
sub getMail
{
    while (<STDIN>) {
        push(@MESSAGES, $_);
        push(@MSGS, $_);
    }

    my $mail = Mail::Internet->new(\@MSGS);
    $MAIL_HEADER = $mail->head();
    $MAIL_BODY = $mail->body();
}

sub main
{
    openlog(basename($0), LOG_PID, LOG_LOCAL5);

    getMail();
    parseCommand();

    closelog();
}

main();
