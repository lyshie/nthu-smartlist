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
use File::Basename;
#
my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my $action        = '';
my $email         = '';
my $username      = '';
my $host          = '';
my $password      = '';
my @subscriptions = ();

my $SENDMAIL      = "/usr/sbin/sendmail -oi -f"; 

my $REMOTE_ADDR   = defined($ENV{'REMOTE_ADDR'}) ? $ENV{'REMOTE_ADDR'} : '';
my $REMOTE_HOST   = defined($ENV{'REMOTE_HOST'}) ? $ENV{'REMOTE_HOST'} : '';
my $REQUEST_URI   = defined($ENV{'REQUEST_URI'}) ? $ENV{'REQUEST_URI'} : '';

sub getUnsubscribeContent
{
    my $result = <<EOF
<h2>電子報取消訂閱結果</h2>
<br />
<code>
EOF
;

    my @lists = getListNames();
    my $pop3 = checkAcceptHosts($email, $password);
    foreach my $s (@subscriptions) {
        foreach my $list (@lists) {
            if ($s eq $list) {
                my %fields = getListFields($list);
                if ($pop3) {
                    removeDist($list, $email);
                    addUnneeded($list, [$email]);
                    $result .= "簡易取消訂閱 [$list] $fields{'DESC'}<br />\n";
                    next;
                }
                my $to = "$list-request\@" . getListDomain();
                my $mailer = basename($0);
                open(FH, "|$SENDMAIL $email $to");
                print FH <<EOF
X-Mailer: $mailer
X-IP-Address: $REMOTE_ADDR 
From: $email
To: $to
Subject: unsubscribe

Unsubscribe from $REMOTE_ADDR ($REMOTE_HOST),
at $REQUEST_URI
EOF
;
                close(FH);
                $result .= "欲取消訂閱 [$list] $fields{'DESC'}，等候確認信回覆<br />\n";
                last;
            }
        }
    }

    chomp($result);
    $result .= <<EOF
</code>
<br />
<div align="center">
<a href="unsubscribe.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;

    return $result;
}

sub getUnsubscribeFormContent
{
    my $accept_hosts = getComboAcceptHosts();
    my $result = <<EOF
<script type="text/javascript" src="/slist/js/widgets/validtips.js"></script>
<script type="text/javascript" src="/slist/js/widgets/validtips2.js"></script>
<h2>取消訂閱電子報</h2>
<br />
<form action="unsubscribe.cgi" method="post">
<input type="hidden" name="sid" value="$sid" />
<table class="light" align="center" width="100%">
	<tr class="listheader">
		<td>簡易取消訂閱(直接取消訂閱)</td>
		<td>一般取消訂閱(<span style="color: yellow;">需回信確認</span>)</td>
	</tr>
	<tr class="list">
		<td style="text-align: justify;">本取消訂閱方式採用本中心提供的電子郵件信箱其密碼來驗證。[<a href="http://net.nthu.edu.tw/2009/faq:mailing_paper" target="_blank">詳細說明</a>]</td>
		<td style="text-align: justify;">如果你的信箱為 Yahoo Mail、Gmail、Hotmail 等非本中心提供的電子郵件信箱，只能採用本方式來取消訂閱電子報，但本取消訂閱方式不限信箱種類(含本中心提供的電子郵件信箱)皆可使用。[<a href="http://net.nthu.edu.tw/2009/faq:mailing_paper" target="_blank">詳細說明</a>]</td>
	</tr>
	<tr class="list">
		<td>
<!-- subscribe -->
<table class="light" align="center">
<tr>
	<td class="lightheader" nowrap="nowrap">電子郵件信箱：</td>
	<td class="light" nowrap="nowrap">
		<input type="text" name="username" value="" size="8" />
		\@$accept_hosts
	</td>
</tr>
<tr>
	<td class="lightheader" nowrap="nowrap">密碼：</td>
	<td class="light" nowrap="nowrap">
		<input type="password" name="password" value="" />
	</td>
</tr>
<tr>
	<td class="lightheader" nowrap="nowrap">驗證碼：</td>
	<td class="light" nowrap="nowrap">
		<input type="text" id="validtips" name="validate" size="6" maxlength="6" />
		<img src="/slist/cgi-bin/validate.cgi" border="0" align="middle" alt="validate" />
	</td>
</tr>
<tr>
	<td class="light" colspan="2" style="text-align: center;">
		<input id="ds" type="submit" name="action" value="簡易取消訂閱" />
	</td>
</tr>
</table>
<!-- subscribe -->
		</td>
		<td>
			電子郵件信箱：<br />
			<input type="text" name="email" /><br />
			驗證碼：
			<input type="text" id="validtips2" name="validate" size="6" maxlength="6" />
			<img src="/slist/cgi-bin/validate.cgi" border="0" align="middle" alt="validate" /><br />
			<input id="cs" type="submit" name="action" value="一般取消訂閱" />
		</td>
	</tr>
</table>
<table class="light" align="center" width="100%">
	<tr class="listheader">
		<td>項次</td>
		<td>
		<input type="button" value="全選" onclick="CheckAll(this.form);" />
		</td>
		<td>電子報名稱</td>
		<td>管理單位</td>
	</tr>
EOF
;
    my @lists = getListNames();
    my $index = 0;
    foreach my $list (@lists) {
        my %fields = getListFields($list);
        next unless ($fields{'VISI'} eq '1');
        $index++;
        my $style = $index % 2;
        $result .= <<EOF
	<tr class="list color$style">
		<td style="background-color: #f6f6f4;">$index</td>
		<td><input type="checkbox" name="lists" value="$fields{'NAME'}" /></td>
		<td>
			<a href="intro.cgi?sid=$sid&amp;list=$fields{'NAME'}">
				[$fields{'NAME'}] $fields{'DESC'}
			</a>
		</td>
		<td>$fields{'ORGA'}</td>
	</tr>
EOF
;
    }

    $result .= <<EOF;
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
    $host     = param('host')     || '';
    $email    = param('email')    || '';
    $password = defined(param('password')) ? param('password') : '';
    @subscriptions = param('lists');

    if ($email eq '') {
        if (($username ne '') && ($host ne '')) {
            $email = "$username\@$host";
        }
    }
    else {
        $username = '';
        $host = '';
        $password ='';
    }

    $email =~ s/[^\w\d\-\_\.\@]//g;
}

sub main
{
    getParams();

    if (($action ne '') && ($email ne '') && (@subscriptions > 0)) {
        checkValidate();
        print header(-charset=>'utf-8');
        print templateReplace('subscribe.ht',
                              {'TITLE'    => getDefaultTitle(),
                               'TOPIC'    => getDefaultTopic(),
                               'MENU'     => getDefaultMenu(),
                               'WIDGET_1' => getWidgetSearch(),
                               'WIDGET_2' => getWidgetLatestArticles(),
                               'WIDGET_3' => getNull(),
                               'CONTENT'  => getUnsubscribeContent(),
                              }
                             );
    }
    else {
        print header(-charset=>'utf-8', -expires => 'now');
        print templateReplace('subscribe.ht',
                              {'TITLE'    => getDefaultTitle(),
                               'TOPIC'    => getDefaultTopic(),
                               'MENU'     => getDefaultMenu(),
                               'WIDGET_1' => getWidgetSearch(),
                               'WIDGET_2' => getWidgetLatestArticles(),
                               'WIDGET_3' => getNull(),
                               'CONTENT'  => getUnsubscribeFormContent(),
                              }
                             );
    }
}

main();
