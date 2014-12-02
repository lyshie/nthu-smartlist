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
use ourSession;
use ListUtils;
use CGI qw(:standard);
use POSIX;
#
my $ADMIN_MSG_FILE = "$Bin/admin.txt";

# user not login, so redirect it to login.cgi
if (!defined(param('sid')) || (param('sid') eq '')) {
    print redirect(-uri => "login.cgi");
}

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

sub getAdminContent
{
    # lyshie_20090331: get the number of dist
    my %fields = getListFields($listname);
    my ($f, $a) = getDists($listname);
    my @unneeded = getUnneeded($listname);

    $f = scalar(@unneeded) || 0;
    $a = scalar(@$a)       || 0;

    # lyshie_20090401: get admin messages
    my $admin_msg = "";
    if (-f "$ADMIN_MSG_FILE") {
        open(FH, "$ADMIN_MSG_FILE");
        while (<FH>) {
            $admin_msg .= $_;
        }
        close(FH);
    }

    my $tips = '';
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime(time()));
    $tips .= "系統時間是 $now";

    my $moderate_num = scalar(getModerateArticles($listname));
    if ($moderate_num > 0) {
        $tips .= "，<span class=\"alert\">尚有 $moderate_num 篇文章待審核</span>。";
    }
    else {
        $tips .= "，<span class=\"alert\">目前沒有文章待審核</span>。";
    }

    $tips .= "\n目前訂閱戶有 <span class=\"alert\">$a</span> 個，自行取消訂閱的有 $f 個。";

    my $result = <<EOF
<h2>管理者模式</h2>
<br />
<code>
"$fields{'MAIN'}"&nbsp;您好，您可使用以下工具來管理您的電子報！
$tips
$admin_msg
</code>
<table border="0" align="center" width="60%">
<tr>
<td align="center">
	<a href="moderate.cgi?sid=$sid">
		<img src="/slist/images/icons/moderate.png" border="0" alt="審查電子報" />
	</a>
	<br />審查電子報
</td>
<td align="center">
	<a href="approved.cgi?sid=$sid">
		<img src="/slist/images/icons/archives.png" border="0" alt="檢視發行紀錄" />
	</a>
	<br />檢視發行紀錄
</td>
<td align="center">
	<a href="settings.cgi?sid=$sid">
		<img src="/slist/images/icons/settings.png" border="0" alt="設定電子報屬性" />
	</a>
	<br />設定電子報屬性
</td>
<td align="center">
	<a href="editdist.cgi?sid=$sid">
		<img src="/slist/images/icons/editdist.png" border="0" alt="編輯訂戶清單" />
	</a>
	<br />編輯訂戶清單
</td>
<td align="center">
        <a href="unneeded.cgi?sid=$sid">
                <img src="/slist/images/icons/dist.png" border="0" alt="下載自行取消訂閱者清單" />
        </a>
        <br />下載「自行取消訂閱者清單」
</td>
</tr>
<tr>
<td colspan="5">&nbsp;</td>
</tr>
<tr>
<td align="center">
	<a href="dist.cgi?sid=$sid">
		<img src="/slist/images/icons/dist.png" border="0" alt="下載訂戶清單" />
	</a>
	<br />下載「訂戶清單」
</td>
<td align="center">
	<a href="log.cgi?sid=$sid">
		<img src="/slist/images/icons/log.png" border="0" alt="操作紀錄" />
	</a>
	<br />操作紀錄
</td>
<td align="center">
	<a href="status.cgi?sid=$sid">
		<img src="/slist/images/icons/stat.png" border="0" alt="統計資訊" />
	</a>
	<br />統計資訊
</td>
<td align="center">
	<a href="help.cgi?sid=$sid">
		<img src="/slist/images/icons/help.png" border="0" alt="操作說明" />
	</a>
	<br />操作說明
</td>
<td align="center">
        <a href="fckeditor.cgi?sid=$sid">
		<img src="/slist/images/icons/edit.png" border="0" alt="編輯電子報" />
        </a>
        <br />編輯電子報
</td>
</tr>
<tr>
<td colspan="5">&nbsp;</td>
</tr>
<tr>
<td align="center">
	<a href="switch.cgi?sid=$sid">
		<img src="/slist/images/icons/settings.png" border="0" alt="切換電子報" />
	</a>
	<br />切換電子報
</td>
</tr>
</table>
EOF
;
    return $result;
}

sub main
{
    print header(-charset=>'utf-8');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getAdminMenu($sid),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetCalendar("list.cgi",
                                                           param('m'),
                                                           param('y')),
                           'WIDGET_3' => getWidgetSession(),
                           'CONTENT'  => getAdminContent(),
                          }
                         );
}

main();
