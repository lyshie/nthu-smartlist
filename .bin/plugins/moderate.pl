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
#
# Shie, Li-Yi <lyshie@mx.nthu.edu.tw>
# 1. A moderate function for SmartList (replace flist)
#
umask(0000);
use FindBin qw($Bin);
#
use Mail::Header;
use Mail::Internet;
use MIME::Words qw(:all);
use File::Basename;
use File::Copy;
use Unix::Syslog qw(:macros :subs);
use Email::Date;
#
use lib "$Bin";
use ListUtils;
use ListLog;
#
my $LOGFILE     = "$Bin/log";
my $LISTNAME    = $ARGV[0] || die("Error: No listname\n");
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

my $SENDMAIL    = "/usr/sbin/sendmail -oi -f $LISTNAME\@" . getListDomain();
my $FLIST       = "$SMARTLIST_PATH/.bin/flist";
#

# lyshie: get the command and parameters from subject
sub getCommand
{
    my $subject = getDecodedSubject($MAIL_HEADER->get('subject'));
    chomp($subject);

    my ($list, $command, $remainder) = ('', '');
    if ($subject =~ m/^.*?\[([\w\-]+)\]\s+COMMAND\s+(\w+)\s+(.*)/si) {
        $list = $1 if defined($1);
        $command = $2 if defined($2);
        $remainder = $3 if defined($3);
    }

    if ($list ne $LISTNAME) {
        $command = '';
    }

    return (uc($command), $remainder);
}

# lyshie: set the subject of return mail according to its original encoding
sub setSubject
{
    my $orig =
        [getDecodedSubject($MAIL_HEADER->get('subject')), $SUBJECT_CHARSET];

    my $command = ["[$LISTNAME] COMMAND DISCARD $UID - ", $SUBJECT_CHARSET];

    my @subjects = ($command, $orig);
    foreach my $subject (@subjects) {
        chomp($subject->[0]);
        if ($subject->[0] eq '') {
            next;
        }
        if (!defined($subject->[1])) {
            $subject->[1] = $SUBJECT_CHARSET;
        }
        $SUBJECT .= encode_mimeword($subject->[0],
                                    $SUBJECT_ENCODING,
                                    $subject->[1]
                                    );
    }
}

# lyshie: command 'approve', copy to approved and delete moderate
sub commandApprove
{
    my $remainder = shift;
    my $id = '';

    $remainder =~ m/\s*(\d+)\s*/;
    $id = $1 if defined($1);

    my $file = "$SMARTLIST_PATH/$LISTNAME/moderate/$id";
    if (-f $file) {
        my @msgs = ();
        open(FH, $file);
        while (<FH>) {
            push(@msgs, $_);
        }
        close(FH);

        my $mail = Mail::Internet->new(\@msgs);
        my $mh = $mail->head();
        my $compose_date = $mh->get('date') || '';
        my $approved_by  = $MAIL_HEADER->get('from') || '';
        $mh->add('compose-date', $compose_date);
        $mh->add('x-approved-by', $approved_by);
        $mh->replace('date', format_date());

        $mh->delete('x-original-to');
        $mh->delete('delivered-to');
        $mh->delete('cc');
        $mh->delete('bcc');
        

        open(CMD, "|$FLIST $LISTNAME");
        print CMD $mail->as_string();
        close(CMD);

        my $approved_path = "$SMARTLIST_PATH/$LISTNAME/approved";
        mkdir($approved_path) if (!-d $approved_path);

        my $approved_file = "$approved_path/$id";

        # lyshie_20080729: set the right permissions to access
        #umask(0000);
        copy($file, $approved_file);
        unlink($file);

        syslog(LOG_INFO,
               "The article has been approved. (listname=%s, id=%s)",
               $LISTNAME,
               $id
              );


        logToList($LISTNAME,
                  "[%s] ARTICLE APPROVED (%s)",
                  basename($0),
                  $id
                 );

        setPublish($id, $approved_file);
    }
}

# lyshie: just delete moderate
sub commandDiscard
{
    my $remainder = shift;
    my $id = '';

    $remainder =~ m/\s*(\d+)\s*/;
    $id = $1 if defined($1);

    my $file = "$SMARTLIST_PATH/$LISTNAME/moderate/$id";
    if (-f $file) {
        my $num = unlink($file);

        syslog(LOG_INFO,
               "The article has been discarded. (listname=%s, id=%s, deleted_files=%s)",
               $LISTNAME,
               $id,
               $num
              );


        logToList($LISTNAME,
                  "[%s] ARTICLE DISCARDED (%s, %s)",
                  basename($0),
                  $id,
                  $num
                 );
    }
}

# lyshie: publish an article by using symbolic link
sub setPublish
{
    my ($id, $source) = @_;
    my %fields = getListFields($LISTNAME);

    if (%fields) {
        if ($fields{'PUBL'} eq '1') {
            my $publish_path = "$SMARTLIST_PATH/$LISTNAME/publish";
            mkdir($publish_path) if (!-d $publish_path);
            symlink($source, "$publish_path/$id");

            syslog(LOG_INFO,
                   "The article has been published. (listname=%s, id=%s)",
                   $LISTNAME,
                   $id
                  );

            logToList($LISTNAME,
                      "[%s] ARTICLE PUBLISHED (%s)",
                      basename($0),
                      $id
                     );
        }
    }
}

# lyshie: make a copy to moderate
sub setModerate
{
    my $moderate = "$SMARTLIST_PATH/$LISTNAME/moderate";
    mkdir($moderate) if (!-d $moderate);
    #umask(0000);
    open(FH, ">$moderate/$UID");
    foreach (@MESSAGES) {
        print FH $_;
    }
    close(FH);

    syslog(LOG_INFO,
           "The article is waiting for being moderated. (listname=%s, id=%s)",
           $LISTNAME,
           $UID
          );
    my $subject = getDecodedSubject($SUBJECT);
    syslog(LOG_INFO,
           "Decoded subject (listname=%s, id=%s, subject=%s)",
           $LISTNAME,
           $UID,
           $subject
          );


    logToList($LISTNAME,
              "[%s] WAIT FOR MODERATING (%s, %s)",
              basename($0),
              $UID,
              $subject
             );
}

# lyshie: notify the moderator and attach a mail
sub sendModerate
{
    # lyshie: replace the important fields
    $MAIL_HEADER->replace('subject', $SUBJECT);
        #$MAIL_HEADER->replace('from', "$LISTNAME\@" . getListDomain());
    $MAIL_HEADER->replace('to', $MAINTAINER);
    $MAIL_HEADER->replace('reply-to', "$LISTNAME\@" . getListDomain());
    $MAIL_HEADER->replace('date', format_date());
    $MAIL_HEADER->replace('x-mailer', basename($0));
    # lyshie: remove unneeded fields
    $MAIL_HEADER->delete('x-original-to');
    $MAIL_HEADER->delete('delivered-to');
        #$MAIL_HEADER->delete('reply-to'); 
        #$MAIL_HEADER->delete('date');
    $MAIL_HEADER->delete('cc');
    $MAIL_HEADER->delete('bcc');
        #$MAIL_HEADER->add('x-loop', "$LISTNAME\@" . getListDomain());
    #syslog(LOG_INFO,
    #       "%s",
    #       $MAIL_HEADER->get('return-path'),
    #      );
    open(FH, "|$SENDMAIL $MAINTAINER");
    printf FH ("%s\n", $MAIL_HEADER->as_string());
    foreach (@$MAIL_BODY) {
        printf FH ("%s", $_);
    }
    close(FH);
}

# lyshie: parse the subject and check if it contains the command part
sub parseCommand
{
    my $remainder = '';
    ($COMMAND, $remainder) = getCommand();

    if ($COMMAND eq 'APPROVE') {
        commandApprove($remainder);
    }
    elsif ($COMMAND eq 'DISCARD') {
        commandDiscard($remainder);
    }
    elsif ($COMMAND eq 'HELP') {
    }
    else {
        setSubject();
        setModerate();
        sendModerate();
    }
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
