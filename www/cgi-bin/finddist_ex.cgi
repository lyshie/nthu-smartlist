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
use ListCheck;
use CGI qw(:standard);
use Email::Valid;
use Unix::Syslog qw(:macros :subs);
#

my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my $action   = '';
my $email    = '';
my $SENDMAIL = "/usr/sbin/sendmail -oi -f DO-NOT-REPLY\@" . getListDomain();

my $REMOTE_ADDR   = defined($ENV{'REMOTE_ADDR'}) ? $ENV{'REMOTE_ADDR'} : '';
my $REMOTE_HOST   = defined($ENV{'REMOTE_HOST'}) ? $ENV{'REMOTE_HOST'} : '';
my $REQUEST_URI   = defined($ENV{'REQUEST_URI'}) ? $ENV{'REQUEST_URI'} : '';

sub getFindDistContent
{
    my $msg = "";

    if ($email) {
        my $result = "";

        my @lists = getListNames();
        my %subscriptions = ();
        my $index = 0;
        foreach my $list (@lists) {
            my %fields = getListFields($list);
            next unless ($fields{'VISI'} eq '1');
            $index++;
            my ($fixed, $auto) = getDists($list);
            foreach (@$auto) {
                if ($email eq $_) {
                    $subscriptions{$list} = '1';
                    last;
                }
            }
            if (defined($subscriptions{$list})) {
                $result .= qq{[$fields{'NAME'}] $fields{'DESC'}} . "\n"; 
            }
        }

#---------------
        my $domain = getListDomain();
        my $file = "$Bin/finddist_ex.txt";
        my $finddist_part = '';

        open(FH, "$file");
        while (<FH>) {
            $finddist_part .= $_;
        }
        close(FH);

        $finddist_part =~ s/#IP#/$REMOTE_ADDR/gm;
        $finddist_part =~ s/#RESULT#/$result/gm;

        open(FH, "|$SENDMAIL $email");

        print FH <<EOF
From: DO-NOT-REPLY\@$domain
To: $email
Subject: Query your subscription
$finddist_part
EOF
;
        close(FH);
        syslog(LOG_INFO,
               "Query subscription. (email=%s, remote_addr=%s)",
               $email,
               $REMOTE_ADDR
              );
#---------------
        $msg .= <<EOF
        <code>查詢訂閱結果已寄出至 $email！</code>
EOF
;
    }
    else {
        $msg .= <<EOF
	<code>無效的 Email，無法寄出查詢訂閱結果！</code>
EOF
;
    }

    $msg .= <<EOF
<br />
<div align="center">
<a href="finddist_ex.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;

    return $msg;
}

sub getFindDistFormContent
{
    my $result = <<EOF
<script type="text/javascript" src="/slist/js/widgets/validtips.js"></script>
<h2>查詢訂閱情形</h2>
<br />
<form action="finddist_ex.cgi" method="post">
<input type="hidden" name="sid" value="$sid" />
<table class="light" align="center">
<tr>
	<td class="lightheader">電子郵件信箱：</td>
	<td class="light">
		<input type="text" name="email" value="" size="32" />
	</td>
</tr>
<tr>
	<td class="lightheader">驗證碼：</td>
	<td class="light">
		<input type="text" id="validtips" name="validate" size="6" maxlength="6" />
		<img src="/slist/cgi-bin/validate.cgi" border="0" align="middle" alt="validate" />
	</td>
</tr>
<tr>
	<td class="light" colspan="2" style="text-align: center;">
		<input type="submit" name="action" value="查詢" />
	</td>
</tr>
</table>
</form>
<br />
<div align="center">
<a href="reader.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub getParams
{
    $action = param('action') || '';
    #$action = lc($action);

    $email = param('email') || '';
#    $email =~ s/^\s+//g;
#    $email =~ s/\s+$//g;

#    $email = '' unless Email::Valid->address($email);
}

sub main
{
    getParams();

    if (($action ne '') && ($email ne '')) {
        checkValidate();
        print header(-charset=>'utf-8');
        print templateReplace('index.ht',
                              {'TITLE'    => getDefaultTitle(),
                               'TOPIC'    => getDefaultTopic(),
                               'MENU'     => getDefaultMenu(),
                               'WIDGET_1' => getWidgetSearch(),
                               'WIDGET_2' => getNull(),
                               'WIDGET_3' => getNull(),
                               'CONTENT'  => getFindDistContent(),
                              }
                             );
    }
    else {
        print header(-charset=>'utf-8', -expires => 'now');
        print templateReplace('index.ht',
                              {'TITLE'    => getDefaultTitle(),
                               'TOPIC'    => getDefaultTopic(),
                               'MENU'     => getDefaultMenu(),
                               'WIDGET_1' => getWidgetSearch(),
                               'WIDGET_2' => getNull(),
                               'WIDGET_3' => getNull(),
                               'CONTENT'  => getFindDistFormContent(),
                              }
                             );
    }
}

main();
