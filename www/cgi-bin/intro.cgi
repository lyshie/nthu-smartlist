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

my $list = '';

sub getIntroContent
{
    my %fields = getListFields($list);

    # antispam
    $fields{'MAIL'} =~ s/\./<img src="\/slist\/images\/dot.png" style="vertical-align: bottom;" alt="(dot)" \/>/g;
    $fields{'MAIL'} =~ s/\@/<img src="\/slist\/images\/at.png" style="vertical-align: bottom;" alt="(at)" \/>/g;

    my $url = "";
    $url = "/slist/catalog/$fields{'NAME'}.html"
        if ($fields{'NAME'}
            && (-f "$SMARTLIST_PATH/www/htdocs/catalog/$fields{'NAME'}.html")
           );

    my $result = <<EOF
<h2>電子報資訊</h2>
<br />
<table class="light" align="center">
	<tr>
        	<td class="lightheader">電子報名稱：</td>
		<td class="light">[$fields{'NAME'}] $fields{'DESC'}</td>
	</tr>
	<tr>
		<td class="lightheader">管理單位：</td>
		<td class="light">$fields{'ORGA'}</td>
	</tr>
	<tr>
		<td class="lightheader">管理者姓名：</td>
		<td class="light">$fields{'MAIN'}</td>
	</tr>
	<tr>
		<td class="lightheader">電子郵件信箱：</td>
		<td class="light">$fields{'MAIL'}</td>
	</tr>
	<tr>
		<td class="lightheader">聯絡電話：</td>
		<td class="light">$fields{'PHON'}</td>
	</tr>
	<tr>
		<td class="lightheader">補充說明：</td>
		<td class="light"><a href="$url">內詳</a></td>
	</tr>
	<tr>
		<td class="lightheader">退訂閱資訊範本：</td>
		<td class="light"><a href="unsubscribe_info.cgi?list=$fields{'NAME'}">下載</a></td>
	</tr>
</table>
<br />
<div align="center">
<a href="javascript:history.back()">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub getParams
{
    $list = param('list') || '';
    $list =~ s/[^\w\-]//g;

    if ($list eq '') {
    }
}

sub main
{
    getParams();
    print header(-charset=>'utf-8');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getDefaultMenu(),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetArticles(),
                           'WIDGET_3' => getNull(),
                           'CONTENT'  => getIntroContent(),
                          }
                         );
}

main();
