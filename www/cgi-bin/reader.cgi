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
use CGI qw(:standard);
#
my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

sub getReaderContent
{
    my $result = <<EOF
<h2>訂閱戶專區 (Reader)</h2>
<br />
<table border="0" align="center" width="60%">
<tr>
<td align="center">
	<a href="archives.cgi?sid=$sid">
		<img src="/slist/images/icons/archives.png" border="0" alt="典藏刊物" />
	</a>
</td>
<td>
<b>典藏刊物 (Archives)</b><br />
您可以瀏覽各電子報曾經發行過的刊物。<br />
</td>
</tr>
<tr>
<td align="center">
	<a href="subscribe.cgi?sid=$sid">
		<img src="/slist/images/icons/subscribe.png" border="0" alt="訂閱電子報" />
	</a>
</td>
<td>
<b>訂閱電子報 (Subscribe)</b><br />
若您不是使用本校提供之電子郵件信箱，於訂閱後將收到確認信，待回覆確認信件後即完成訂閱程序；您若是使用本校提供之電子郵件信箱，可透過 POP3 驗證直接在線上完成訂閱程序。<br />
</td>
</tr>
<tr>
<td align="center">
	<a href="unsubscribe.cgi?sid=$sid">
		<img src="/slist/images/icons/unsubscribe.png" border="0" alt="取消訂閱電子報" />
	</a>
</td>
<td>
<b>取消訂閱電子報 (Unsubscribe)</b><br />
若您不是使用本校提供之電子郵件信箱，於取消訂閱後將收到確認信，待回覆確認信件後即完成取消訂閱程序；您若是使用本校提供之電子郵件信箱，可透過 POP3 驗證直接在線上完成取消訂閱程序。<br />
</td>
</tr>
<tr>
<td align="center">
	<a href="finddist.cgi?sid=$sid">
		<img src="/slist/images/icons/finddist.png" border="0" alt="查詢訂閱情形" />
	</a>
</td>
<td>
<b>查詢訂閱情形 (Query)<span class="alert">(限本校電子郵件帳號)</span></b><br />
您可以查詢自己曾經訂閱過哪些電子報。若是使用本校提供之電子郵件信箱，可透過 POP3 驗證直接在線上呈現查詢結果。<br />
</td>
</tr>
<tr>
<td align="center">
        <a href="finddist_ex.cgi?sid=$sid">
                <img src="/slist/images/icons/finddist.png" border="0" alt="查詢
訂閱情形" />
        </a>
</td>
<td>
<b>查詢訂閱情形 (Query)</b><br />
您可以查詢自己曾經訂閱過哪些電子報，查詢結果將寄至您的信箱。<br />
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
                           'MENU'     => getDefaultMenu(),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetLatestArticles(),
                           'WIDGET_3' => getNull(),
                           'CONTENT'  => getReaderContent(),
                          }
                         );
}

main();
