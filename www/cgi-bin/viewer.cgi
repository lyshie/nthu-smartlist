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
use HTML::Entities;
use DB_File;
use Fcntl;
require "extract.pl";
#
my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my ($list, $article) = ('', '');

my $VIEWER_DB = "$Bin/viewer.db";
my %DB = ();
my $COUNT = 0;

sub createDB
{
    tie (%DB, 'DB_File', $VIEWER_DB, O_CREAT|O_RDWR, 0777) ||
        die ("Cannot create or open $VIEWER_DB");
}

sub openDB
{
    tie (%DB, 'DB_File', $VIEWER_DB) ||
        die ("Cannot open $VIEWER_DB");
}

sub readFromDB
{
    my $key = shift;
    my $record = $DB{$key} || 0;
    return $record;
}

sub writeToDB
{
    my $key   = shift;
    my $value = shift;
    $DB{$key} = $value;
}

sub closeDB
{
    untie(%DB);
}

sub getParams
{
    $list    = param('list') || '';
    $article = param('article') || '';
    $list    =~ s/[^\w\-]//g;
    $article =~ s/[^\d]//g;

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
    return unless ($fields{'VISI'} eq '1');
    return unless ($fields{'PUBL'} eq '1');

    # lyshie_20090922: using DB_File to store view counts
    my $file = "$SMARTLIST_PATH/$list/publish/$article";
    if (-f $file) {
        if (!-f $VIEWER_DB) {
            createDB();
        }
        openDB();
            $COUNT = readFromDB("$list.$article");
            $COUNT++;
            writeToDB("$list.$article", $COUNT);
        closeDB();
    }

    $file = "$SMARTLIST_PATH/www/cgi-bin/keywords/$list.$article";
    my @keywords = ();
    my $keyword_part = "";
    if (-f $file) {
        open(FH, "$file");
        while (<FH>) {
            chomp($_);
            push(@keywords, $_);
        }
        close(FH);
        if (@keywords) {
            $keyword_part = qq{<!-- lyshie_20090324: begin n-gram keywords -->
<div><b>關鍵字：</b>};
            foreach (@keywords) {
                my $url = CGI::escape($_);
                my $tag = encode_entities($_, '<>&"');
                $keyword_part .= qq{<a href="search.cgi?sid=$sid&amp;keyword=$url">$tag</a>&nbsp;};
            }
            $keyword_part .= qq{</div>
<!-- lyshie_20090324: end n-gram keywords -->};
        }
    }

    # extract attachments
    my $atta_part = extractMail($list, $article);

    # antispam
    $fields{'MAIL'} =~ s/\./<img src="\/slist\/images\/dot.png" style="vertical-align: bottom;" alt="(dot)" \/>/g;
    $fields{'MAIL'} =~ s/\@/<img src="\/slist\/images\/at.png" style="vertical-align: bottom;" alt="(at)" \/>/g;

    my $domain = getListDomain();
    my $body = encode_entities("I want to subscribe.", '<>&"');

    my $pdf = "$SMARTLIST_PATH/www/htdocs/pdf/$list.$article.pdf";
    my $pdf_part = "";
    if (-f $pdf) {
        $pdf_part = qq{&nbsp;
<a href="/slist/pdf/$list.$article.pdf" target="_blank">
<img src="/slist/images/icons/pdf16.png" border="0" alt="pdf" />
PDF 下載
</a>};
    }

    my $result = <<EOF
<!-- auto-generated -->
<h2>閱讀電子報</h2>
<br />
<table class="light" align="center">
<tr class="listheader">
	<td>電子報名稱</td>
        <td>管理單位</td>
	<td>管理者</td>
	<td>電話</td>
	<td>管理者信箱</td>
</tr>
<tr class="list">
	<td>[$list] $fields{'DESC'}</td>
	<td>$fields{'ORGA'}</td>
	<td>$fields{'MAIN'}</td>
	<td>$fields{'PHON'}</td>
	<td>$fields{'MAIL'}</td>
</tr>
</table>
<br />
<script type="text/javascript" src="/slist/js/widgets/zoom.js"></script>
<script type="text/javascript" src="/slist/js/jquery/plugins/thickbox.js"></script>
<div class="widget">
<a href="javascript:history.back()">
<img src="/slist/images/icons/back16.png" border="0" alt="back" />
回上一頁
</a>
&nbsp;
<a href="view.cgi?sid=$sid&amp;list=$list&amp;article=$article?keepThis=true&amp;TB_iframe=true" id="zoom" class="thickbox">
<img src="/slist/images/icons/zoomin16.png" border="0" alt="zoomin" />
放大閱讀
</a>
$pdf_part
&nbsp;
<a href="view.cgi?sid=$sid&amp;list=$list&amp;article=$article&amp;mode=print" target="_blank">
<img src="/slist/images/icons/print16.png" border="0" alt="print" />
友善列印
</a>
&nbsp;
<a href="/slist/rss/$fields{'NAME'}.xml">
<img src="/slist/images/icons/rss16.png" border="0" alt="RSS" />
RSS 訂閱
</a>
&nbsp;
<a href="mailto:$fields{'NAME'}-request\@$domain?subject=subscribe&amp;body=$body">
<img src="/slist/images/icons/add16.png" border="0" alt="subscribe" />
直接訂閱
</a>
&nbsp;
<a href="list.cgi?sid=$sid&amp;list=$fields{'NAME'}">
<img src="/slist/images/icons/archives16.png" border="0" alt="archives" />
典藏刊物
</a>
&nbsp;
<b>點閱數：</b>$COUNT
</div>
$keyword_part
$atta_part
<div class="shadowed">
<iframe id="viewer" name="viewer" src="view.cgi?sid=$sid&amp;list=$list&amp;article=$article" height="600" frameborder="0">
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
                           'MENU'     => getDefaultMenu(),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetArticles(),
                           'WIDGET_3' => getNull(),
                           'CONTENT'  => getViewContent(),
                          }
                         );
}

main();
