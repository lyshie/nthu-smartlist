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
BEGIN { $INC{'ListCheck.pm'} ||= __FILE__ };

package ListCheck;
use CGI qw(:standard);
use FindBin qw($Bin);
use lib "$Bin";
use ListTemplate;
use File::Basename;
use Unix::Syslog qw(:macros :subs);

our @ISA = qw(Exporter);
our @EXPORT = qw(checkValidate
                );

my $VALIDATE_PATH = "/tmp/validate";

my $_DATA = "";

sub getInvalidContent
{
    my $addr = $ENV{'REMOTE_ADDR'} || '';
    my $result = <<EOF
<h2>驗證碼輸入錯誤</h2>
<br />
<code>
您輸入的驗證碼錯誤！ 
</code>
EOF
;
    syslog(LOG_INFO, "Invalid number. (remote_addr=%s)", $addr);

    return $result;
}

sub checkInvalid
{
    my $previous = $ENV{'HTTP_REFERER'};

    print header(-charset=>'utf-8');
    print ListTemplate::templateReplace('index_redirect.ht',
                          {'META'     => ListTemplate::getRedirectMeta($previous, 3),
                           'TITLE'    => ListTemplate::getDefaultTitle(),
                           'TOPIC'    => ListTemplate::getDefaultTopic(),
                           'MENU'     => ListTemplate::getDefaultMenu(),
                           'WIDGET_1' => ListTemplate::getNull(),
                           'WIDGET_2' => ListTemplate::getNull(),
                           'WIDGET_3' => ListTemplate::getNull(),
                           'CONTENT'  => getInvalidContent(),
                          }
                         );
    exit(0);
}

sub _getParams
{
    my @all = param('validate');
    # lyshie_20080626: allow multiple variables
    foreach (@all) {
        if (defined($_) && ($_ ne '')) {
            $_DATA = $_;
        }
    }
    $_DATA = '' unless defined($_DATA);
    $_DATA =~ s/[^\d]//g;
}

sub _checkValidate
{
    my $data = shift || '';

    $data =~ s/[^\d]//g;

    return 0 unless (-f "$VALIDATE_PATH/$data");

    open(FH, "$VALIDATE_PATH/$data");
    my $time = <FH> || 0;
    chomp($time);
    close(FH);
    unlink("$VALIDATE_PATH/$data");

    if (time() - $time < 10 * 60) {
        my $addr = $ENV{'REMOTE_ADDR'} || '';
        syslog(LOG_INFO, "Valid number. (number=%s, remote_addr=%s)", $data, $addr);
        return 1;
    }
    else {
        return 0;
    }
}

sub checkValidate
{
    _getParams();
    openlog(basename($0), LOG_PID, LOG_LOCAL5);
    checkInvalid unless (_checkValidate($_DATA));
    closelog();
}

1;
