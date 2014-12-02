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

sub getArchivesContent
{
    my $result = <<EOF
<h2>電子報全覽 (Archives)</h2>
<br />
<div align="right">
<a href="/slist/rss/nthu.xml">
訂閱全部電子報 (Subscribe All)
<img src="/slist/images/icons/opml16.png" border="0" alt="OPML" />
</a>
</div>
<br />
<table class="light" align="center" width="100%">
	<tr class="listheader">
		<td>項次</td>
		<td>電子報名稱</td>
		<td>發行單位</td>
		<td>管理者</td>
		<td colspan="2">線上瀏覽</td>
		<td>退訂範本</td>
	</tr>
EOF
;
    my @lists = getListNames();
    my $index = 0;
    foreach my $list (@lists) {
        my %fields = getListFields($list);
        my $status = '';
        next unless ($fields{'VISI'} eq '1');
        if ($fields{'PUBL'} eq '1') {
            $status = <<EOF
		<td>
			<a href="list.cgi?sid=$sid&amp;list=$fields{'NAME'}">
			閱覽
			</a>
		</td>
		<td>
			<a href="/slist/rss/$fields{'NAME'}.xml">
			<img src="/slist/images/icons/rss16.png" border="0" alt="RSS" />
			</a>
		</td>
EOF
;
        }
        else {
		$status = <<EOF
		<td colspan="2">&nbsp;</td>
EOF
;
        }

        $index++;
        my $style = $index % 2;
        $result .= <<EOF
	<tr class="list color$style">
		<td style="background-color: #f6f6f4;">$index</td>
		<td style="text-align: left;">
		<a href="intro.cgi?sid=$sid&amp;list=$list">
		[$list] $fields{'DESC'}
		</a>
		</td>
		<td>
		<a href="intro.cgi?sid=$sid&amp;list=$list">
		$fields{'ORGA'}
		</a>
		</td>
		<td>
		<a href="intro.cgi?sid=$sid&amp;list=$list">
		$fields{'MAIN'}
		</a>
		</td>
		$status
		<td>
		<a href="unsubscribe_info.cgi?sid=$sid&amp;list=$list">
		下載
		</a>
		</td>
	</tr>
EOF
;
    }

    $result .= <<EOF
</table>
<br />
<div align="center">
<a href="javascript:history.back()">回上一頁</a>
</div>
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
                           'WIDGET_3' => getWidgetContainer(
                                             getWidgetCalendar("list.cgi",
                                                               param('m'),
                                                               param('y')),
                                         ),
                           'CONTENT'  => getArchivesContent(),
                          }
                         );
}

main();
