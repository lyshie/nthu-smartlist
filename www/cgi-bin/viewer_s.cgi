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
use ourSession;
use CGI qw(:standard);
#
my ($listname, $sid) = sessionCheck();

my ($list, $article, $mode) = ($listname, '', '');
$sid =~ s/[^0-9a-zA-Z]//g;

sub getParams
{
    #$list    = param('list') || '';
    $article = param('article') || '';
    $list    =~ s/[^\w\-]//g;
    $article =~ s/[^\d]//g;

    $mode = param('mode') || '';

    if (($list eq '') || ($article eq ''))  {
    }
}

sub getViewTopic
{
    my $result = '<h1>閱讀電子報</h1>';
    return $result;
}

sub getViewContent
{
    my %fields = getListFields($list);
    #return unless ($fields{'VISI'} eq '1');
    #return unless ($fields{'PUBL'} eq '1');

    # antispam
    $fields{'MAIL'} =~ s/\./<img src="\/slist\/images\/dot.png" style="vertical-align: bottom;" alt="(dot)" \/>/g;
    $fields{'MAIL'} =~ s/\@/<img src="\/slist\/images\/at.png" style="vertical-align: bottom;" alt="(at)" \/>/g;

    my $result = <<EOF
<!-- auto-generated -->
<h2>閱讀電子報</h2>
<br />
<table class="light" align="center">
<tr class="listheader">
	<td>電子報名稱</td>
        <td>管理單位</td>
	<td>管理者</td>
	<td>管理者信箱</td>
</tr>
<tr class="list">
	<td>[$list] $fields{'DESC'}</td>
	<td>$fields{'ORGA'}</td>
	<td>$fields{'MAIN'}</td>
	<td>$fields{'MAIL'}</td>
</tr>
</table>
<br />
<div class="shadowed">
<iframe id="viewer" name="viewer" src="view_s.cgi?sid=$sid&amp;list=$list&amp;article=$article&amp;mode=$mode" height="600" frameborder="0">
</iframe>
</div>
<br />
<div align="center">
<a href="javascript:history.back()">回上一頁</a>
</div>
<!-- auto-generated -->
EOF
;
    return $result;
}

sub main
{
    getParams();
    print header(-charset=>'utf-8');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getAdminMenu($sid),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetSession(),
                           'WIDGET_3' => getNull(),
                           'CONTENT'  => getViewContent(),
                          }
                         );
}

main();
