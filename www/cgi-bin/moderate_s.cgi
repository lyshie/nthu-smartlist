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
use FindBin qw($Bin);
use lib "$Bin";
use ListTemplate;
use ListUtils;
use ListLog;
use ourSession;
use CGI qw(:standard);
use File::Basename;
use Unix::Syslog qw(:macros :subs);
use File::Basename;
#

my $SENDMAIL      = "/usr/sbin/sendmail -oi -f";
my $REMOTE_ADDR   = defined($ENV{'REMOTE_ADDR'}) ? $ENV{'REMOTE_ADDR'} : '';
my $REMOTE_HOST   = defined($ENV{'REMOTE_HOST'}) ? $ENV{'REMOTE_HOST'} : '';
my $REQUEST_URI   = defined($ENV{'REQUEST_URI'}) ? $ENV{'REQUEST_URI'} : '';

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

my (@approve, @discard) = ((), ());
my $action = '';

sub getModerateContent
{
    my $result = <<EOF
<h2>審查電子報結果</h2>
<br />
<code>
EOF
;
    my $maintainer = getListMaintainer($listname);

    if ($action eq 'APPROVE') {
        foreach my $id (@approve) {
            if (-f "$SMARTLIST_PATH/$listname/moderate/$id") {
                my $to = "$listname\@" . getListDomain();
                my $mailer = basename($0);
                open(FH, "|$SENDMAIL $maintainer $to");
                print FH <<EOF
X-Mailer: $mailer
From: $maintainer
To: $to
Subject: [$listname] COMMAND APPROVE $id

Send command APPROVE from $REMOTE_ADDR ($REMOTE_HOST),
at $REQUEST_URI
EOF
;
                $result .= <<EOF
編號 $id 電子報，完成發行；
EOF
;
                syslog(LOG_INFO,
                       "Moderator approve OK. (sid=%s, id=%s)",
                       $sid,
                       $id,
                      );

                logToList($listname,
                          "[%s] APPROVE OK (%s, %s)",
                          basename($0),
                          $sid,
                          $id
                         );
            }
            else {
                $result .= <<EOF
編號 $id 電子報，不存在！
EOF
;
            }
        }
    }
    elsif ($action eq 'DISCARD') {
        foreach my $id (@discard) {
            if (-f "$SMARTLIST_PATH/$listname/moderate/$id") {
                my $to = "$listname\@" . getListDomain();
                my $mailer = basename($0);
                open(FH, "|$SENDMAIL $maintainer $to");
                print FH <<EOF
X-Mailer: $mailer
From: $maintainer
To: $to
Subject: [$listname] COMMAND DISCARD $id

Send command DISCARD from $REMOTE_ADDR ($REMOTE_HOST),
at $REQUEST_URI
EOF
;
                $result .= <<EOF
編號 $id 電子報，完成刪除；
EOF
;
                syslog(LOG_INFO,
                       "Moderator discard OK. (sid=%s, id=%s)",
                       $sid,
                       $id,
                      );

                logToList($listname,
                          "[%s] DISCARD OK (%s, %s)",
                          basename($0),
                          $sid,
                          $id
                         );
            }
            else {
                $result .= <<EOF
編號 $id 電子報，不存在！
EOF
;
            }
        }
    }
    else {
        $result .= <<EOF
未指定動作，請選擇發行或刪除電子報！
EOF
;
    }

    $result .= <<EOF
</code>
<br />
<div align="center">
<a href="moderate.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub getParams
{
    @approve = param('approve');
    @discard = param('discard');
    $action = defined(param('action')) ? param('action') : '';
}

sub main
{
    openlog(basename($0), LOG_PID, LOG_LOCAL5);

    getParams();
    print header(-charset=>'utf-8');
    print templateReplace('moderate.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getAdminMenu($sid),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetLatestArticles(),
                           'WIDGET_3' => getWidgetSession(),
                           'CONTENT'  => getModerateContent(),
                          }
                         );

    closelog();
}

main();
