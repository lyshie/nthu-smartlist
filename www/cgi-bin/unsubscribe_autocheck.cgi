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

my $RAND_MAX      = 999999;
my $UID           = time() . int(rand($RAND_MAX));
my $SENDMAIL      = "/usr/sbin/sendmail -oi -f DO-NOT-REPLY\@" . getListDomain();
my $LISTS_PATH    = "$Bin/lists";

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
    if ($pop3) {
        foreach my $s (@subscriptions) {
            foreach my $list (@lists) {
                if ($s eq $list) {
                    my %fields = getListFields($list);
                    removeDist($list, $email);
                    addUnneeded($list, [$email]);
                    $result .= "簡易取消訂閱 [$list] $fields{'DESC'}\n";
                }
            }
        }
    }
    else {
        $result .= "已寄出確認信至您的信箱，欲取消訂閱的電子報清單如下：\n";

        my @temp_list = ();
        my $list_msg  = '';

        foreach my $s (@subscriptions) {
            foreach my $list (@lists) {
                if ($s eq $list) {
                    my %fields = getListFields($list);
                    push(@temp_list, $list);
                    $result .= "[$list] $fields{'DESC'}\n";
                    $list_msg .= "[$list] $fields{'DESC'}\n";
                }
            }
        }

        # lyshie_20110314: keep subscribe info
        open(FH, ">$LISTS_PATH/u$UID");
        print FH "$email\n";
        foreach (@temp_list) {
            print FH "$_\n";
        }
        close(FH);

        # lyshie_20110314: template process
        my $file = "$Bin/unsubscribe.txt";
        my $unsubscribe_part = '';

        open(FH, "$file");
        while (<FH>) {
            $unsubscribe_part .= $_;
        }
        close(FH);

        chomp($list_msg);
        $unsubscribe_part =~ s/#IP#/$REMOTE_ADDR/gm;
        $unsubscribe_part =~ s/#LISTS#/$list_msg/gm;
        $unsubscribe_part =~ s/#UID#/u$UID/gm;
        $unsubscribe_part =~ s/#EMAIL#/$email/gm;

        my $domain = getListDomain();
        my $to = $email;
        my $mailer = basename($0);
        open(FH, "|$SENDMAIL $email");
        print FH <<EOF
X-Mailer: $mailer
X-IP-Address: $REMOTE_ADDR 
From: DO-NOT-REPLY\@$domain
To: $to
Subject: unsubscribe confirm u$UID
$unsubscribe_part
EOF
;
        close(FH);
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
    my $list_array = join('", "', @subscriptions);
    $list_array = qq{"$list_array"} if ($list_array);

    my $accept_hosts = getComboAcceptHosts();
    my $result = <<EOF
<script type="text/javascript" src="/slist/js/widgets/validtips.js"></script>
<script type="text/javascript" src="/slist/js/widgets/validtips2.js"></script>
<script type="text/javascript">
//<![CDATA[
\$(function() {
	var lists = [$list_array];
	for (var key in lists) {
		\$("#checkbox_" + lists[key]).attr('checked','checked');
		\$("#tr_" + lists[key]).css("background-color", "#ff0");
	}

	\$('html,body').animate({scrollTop: \$("#tr_" + lists[key]).offset().top},'slow');
});
//]]>
</script>
<h2>取消訂閱電子報</h2>
<br />
<form action="unsubscribe.cgi" method="post">
<input type="hidden" name="sid" value="$sid" />
<table class="light" align="center" width="100%">
	<tr class="listheader">
		<td>簡易取消訂閱(直接取消訂閱)</td>
		<td>一般取消訂閱(<span style="color: yellow;">需點選確認</span>)</td>
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
    # lyshie_20121025: just show the subscriptions
    if (@subscriptions) {
        foreach my $i (0 .. $#lists) {
            if ( !grep { $lists[$i] eq $_ } @subscriptions ) {
                delete($lists[$i]);
            }
        }
    }
    my $index = 0;
    foreach my $list (@lists) {
        my %fields = getListFields($list);
        next unless ($fields{'VISI'} eq '1');
        $index++;
        my $style = $index % 2;
        $result .= <<EOF
	<tr class="list color$style" id="tr_$fields{'NAME'}">
		<td style="background-color: #f6f6f4;">$index</td>
		<td><input type="checkbox" name="lists" value="$fields{'NAME'}" id="checkbox_$fields{'NAME'}" /></td>
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


    foreach (@subscriptions) {
        $_ =~ s/[^\w\-]//g;
    }
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