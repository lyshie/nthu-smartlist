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
BEGIN { $INC{'ListBounce.pm'} ||= __FILE__ };

package ListBounce;
umask(0000);
use FindBin qw($Bin);
use File::Basename;
use lib "$Bin";
use ListUtils;
use ListLog;
use Unix::Syslog qw(:macros :subs);

our @ISA = qw(Exporter);
our @EXPORT = qw(checkUndelivered
                 extractMailAddress
                 addToBounce
                 bounceDist
                );

my @BOUNCE_SENDERS = ('MAILER-DAEMON',
                     );

my @BOUNC_SUBJECTS = ('Undelivered Mail Returned to Sender',
                      'Returned Mail',
                      'Delivery failure',
                      'Unavailable Delivery',
                      'Undelivered Mail',
                      'failed delivery',
                     );

my $RAND_MAX      = 999999;

# lyshie_20080908: 5 times a week
my $BOUNCE_TIMES  = 5;
my $BOUNCE_PERIOD = 7 * 24 * 60 * 60;

sub checkUndelivered
{
    my $sender  = shift || '';
    my $subject = shift || '';
    my $tags    = shift || '';
            open(FH, ">>/usr/local/slist/tmp/subject");
            print FH "$subject\n";
            close(FH);

    # check sender
    my $ismailer = 0;
      # return false
    foreach my $s (@BOUNCE_SENDERS) {
        if ($sender =~ m/$s/i) {
            $ismailer = 1;
            last;
        }
    }

    return 0 unless ($ismailer);

    # check subject
    my $issubject = 0;
      # return false
    foreach my $s (@BOUNC_SUBJECTS) {
        if ($subject =~ m/$s/i) {
            $issubject = 1;
            last;
        }
    }

    return $issubject;
}

sub extractMailAddress
{
    my $body = shift || '';

    # lyshie_20101215: bounce many times
    my @result = ();

    my $domain = getListDomain();
    my %emails = (); # bounce 1 time
    my %users  = (); # bounce many times

    foreach my $line (@$body) {
        if ($line =~ m/Relaying mail to\s+(.+?)\s+is not allowed/im) {
            if (defined($1)) {
                my $e = $1;
                # check if localhost
                if ($e !~ m/\Q$domain\E/i) {
                    $users{$e} = 1;
                }
            }
        }

        if ($line =~ m/Final\-Recipient:.*?\s([a-zA-Z0-9\.\-_]+@([a-zA-Z0-9\-_]+\.)+[a-zA-Z0-9\-_]+)/m) {
            if (defined($1)) {
                my $e = $1;
                # check if localhost
                if ($e !~ m/\Q$domain\E/i) {
                    $emails{$e} = 1;
                }
            }
        }

        if ($line =~ m/([a-zA-Z0-9\.\-_]+@([a-zA-Z0-9\-_]+\.)+[a-zA-Z0-9\-_]+)\s+\[.*\]/m) {
            if (defined($1)) {
                my $e = $1;
                # check if localhost
                if ($e !~ m/\Q$domain\E/i) {
                    $emails{$e} = 1;
                }
            }
        }
    }

    # return @emails (non-duplicated / valid)
    push(@result, keys(%emails)); # bounce 1 time

    foreach my $u (keys(%users)) {
        for (1..$BOUNCE_TIMES) {
            push(@result, $u);   # bounce many times
        };
    }

    return @result;
}

sub addToBounce
{
    my $listname = shift || '';
    my $emails   = shift;

    my %fields = getListFields($listname);
    return unless (%fields);

    my $path = "$SMARTLIST_PATH/$listname/bounces";
    mkdir($path) unless (-d $path);
    return unless (-d $path);

    my $BID = time() . "_" . int(rand($RAND_MAX));
    my $file = "$path/$BID";

    open(FH, ">$file");
        foreach (@$emails) {
            print FH "$_\n";
        }
    close(FH);


            open(FH, ">>/usr/local/slist/tmp/bounce");
                foreach (@$emails) {
                    print FH "$_\n";
                }
            close(FH);


    return $emails;
}

sub bounceDist
{
    my $listname = shift || '';
    my $times    = shift || $BOUNCE_TIMES;
    my $period   = shift || $BOUNCE_PERIOD;

    my %fields = getListFields($listname);
    return unless (%fields);

    my %bounced = ();

    # lyshie_20080908: list all bounced logs
    my $path = "$SMARTLIST_PATH/$listname/bounces";
    my @files = ();
    opendir(DH, $path);
        @files = grep { -f "$path/$_" } readdir(DH);
    closedir(DH);

    my $now = time();
    my ($filename, $rand) = ('', '');
    foreach my $f (@files) {
        ($filename, $rand) = split(/_/, $f);
        # lyshie_20080908: check if a valid bounced log
        if (($now - $filename) < $period) {
            # lyshie_20080908: get the bounced emails
            open(FH, "$path/$f");
            foreach my $line (<FH>) {
                chomp($line);
                if ($line ne '') {
                    $bounced{$line} = 0 unless (defined($bounced{$line}));
                    $bounced{$line}++;
                }
            }
            close(FH);

        }
        else {
            # lyshie_20090318: unlink old processed files
            unlink("$path/$f");
        }
    }

    # lyshie_20080908: get the bounced emails
    foreach (keys(%bounced)) {
        delete ($bounced{$_}) if ($bounced{$_} < $times);
    }

    foreach my $e (keys(%bounced)) {
        my $is_removed = 0;
        ($is_removed) = removeDist($listname, $e);
        if ($is_removed) {
        openlog(basename($0), LOG_PID, LOG_LOCAL5);
        syslog(LOG_INFO,
               "The dist has been bounced. (listname=%s, email=%s)",
               $listname,
               $e
              );
        closelog();
        logToList($listname, "[%s] MAIL BOUNCED (%s, %d, %s)", basename($0), $e, $bounced{$e}, $now); 
        printf("bounced[%s] %s\n", $bounced{$e}, $e);
        }
    }

    return keys(%bounced);
}
