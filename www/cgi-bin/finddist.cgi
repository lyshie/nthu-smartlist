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
#

my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my $action        = '';
my $email         = '';
my $username      = '';
my $host          = '';
my $password      = '';

my $REMOTE_ADDR   = defined($ENV{'REMOTE_ADDR'}) ? $ENV{'REMOTE_ADDR'} : '';
my $REMOTE_HOST   = defined($ENV{'REMOTE_HOST'}) ? $ENV{'REMOTE_HOST'} : '';
my $REQUEST_URI   = defined($ENV{'REQUEST_URI'}) ? $ENV{'REQUEST_URI'} : '';

sub getFindDistContent
{
    my $result = <<EOF
<h2>電子報查詢訂閱結果</h2>
<br />
EOF
;
    my $pop3 = checkAcceptHosts($email, $password);
    if ($pop3) {
        $result .= <<EOF
<table class="light" align="center" width="80%">
	<tr class="listheader">
		<td>項次</td>
		<td>電子報名稱</td>
		<td>管理單位</td>
		<td>訂閱情形</td>
	</tr>
EOF
;
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
            my $style = defined($subscriptions{$list}) ?
                     ' style="background-color: #ff0"' : '';
            my $status = defined($subscriptions{$list}) ? '已訂閱' : '&nbsp;';
            $result .= <<EOF
	<tr class="list">
		<td style="background-color: #f6f6f4;">$index</td>
		<td$style>
			<a href="intro.cgi?sid=$sid&amp;list=$fields{'NAME'}">
			[$fields{'NAME'}] $fields{'DESC'}
			</a>
		</td>
		<td$style>$fields{'ORGA'}</td>
		<td$style>$status</td>
	</tr>
EOF
;
        }
        $result .= <<EOF
</table>
EOF
;
    }
    else {
        $result .= <<EOF
	<code>驗證失敗，無法查詢訂閱情形！</code>
EOF
;
    }

    $result .= <<EOF
<br />
<div align="center">
<a href="finddist.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;

    return $result;
}

sub getFindDistFormContent
{
    my $accept_hosts = getComboAcceptHosts();
    my $result = <<EOF
<script type="text/javascript" src="/slist/js/widgets/validtips.js"></script>
<h2>查詢訂閱情形 (限本校電子郵件帳號)</h2>
<br />
<form action="finddist.cgi" method="post">
<input type="hidden" name="sid" value="$sid" />
<table class="light" align="center">
<tr>
	<td class="lightheader">電子郵件信箱：</td>
	<td class="light">
		<input type="text" name="username" value="" size="8" />
		\@$accept_hosts
	</td>
</tr>
<tr>
	<td class="lightheader">密碼：</td>
	<td class="light">
                <input type="password" name="password" value="" size="12" />
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

    $username = param('username') || '';
    $host     = param('host') || '';

    if (($username ne '') && ($host ne '')) {
        $email = "$username\@$host";
        $email =~ s/[^\w\d\-\_\.\@]//g;
    }

    $password = defined(param('password')) ? param('password') : '';
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
