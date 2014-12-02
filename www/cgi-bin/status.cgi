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
#

my ($listname, $sid) = sessionCheck();

sub getStatusContent
{
    my $result = <<EOF
<h2>統計資訊</h2>
<br />
EOF
;
    my @listnames = getListNames();

    
    # total approved, publish
    $result .= <<EOF
	<table class="light" align="center" width="100%">
	<tr class="listheader">
		<td>電子報名稱</td>
		<td>已審核電子報數</td>
		<td>已公開電子報數</td>
		<td>待審查電子報數</td>
	</tr>
EOF
;
    my %approved = ();
    my %publish  = ();
    my %moderate = ();
    my $total_a  = 0;
    my $total_p  = 0;
    my $total_m  = 0;
    foreach (@listnames) {
        $approved{$_} = scalar(getApprovedArticles($_));
        $total_a     += $approved{$_};
        $publish{$_}  = scalar(getPublishArticles($_));
        $total_p     += $publish{$_};
        $moderate{$_} = scalar(getModerateArticles($_));
        $total_m     += $moderate{$_};
    }

    my $index = 0;
    foreach (@listnames) {
        $index++;
        my $style = $index % 2;
        my ($a, $p, $m) = (0, 0, 0);
        eval {
            $a = sprintf("%.2f", 100 * $approved{$_} / $total_a);
        };
        eval {
            $p = sprintf("%.2f", 100 * $publish{$_}  / $total_p);
        };
        eval {
            $m = sprintf("%.2f", 100 * $moderate{$_} / $total_m);
        };
        my %fields = getListFields($_);
        $result .= <<EOF
	<tr class="list color$style">
		<td>[$_] $fields{'DESC'}</td>
		<td>$approved{$_} ($a%)</td>
		<td>$publish{$_} ($p%)</td>
		<td>$moderate{$_} ($m%)</td>
	</tr>
EOF
;
    }
    $result .= <<EOF
	<tr class="list">
		<td>總和</td>
		<td>$total_a</td>
		<td>$total_p</td>
		<td>$total_m</td>
	</tr>
	</table>
EOF
;

    # total keywords
    my %keywords = ();
    open(FH, "$SMARTLIST_PATH/www/cgi-bin/phrases/freq");
    while (<FH>) {
        chomp($_);
        my ($keyword, $freq) = split(/=/, $_);
        $keywords{$keyword} = $freq;
    }
    close(FH);
    my @tmp = sort { $keywords{$b} <=> $keywords{$a} } keys(%keywords);
    @tmp = @tmp[0..9];

    $result .= <<EOF
	<table class="light" align="center" width="100%">
	<tr class="listheader">
		<td>關鍵字</td>
		<td>出現次數</td>
	</tr>
EOF
;
    foreach (@tmp) {
        $result .= <<EOF
	<tr class="list">
		<td>$_</td>
		<td>$keywords{$_}</td>
	</tr>
EOF
;
    }

    $result .= <<EOF
	</table>
EOF
;


    $result .= <<EOF
<br />
<div align="center">
	<a href="admin.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub getParams
{
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
                           'CONTENT'  => getStatusContent(),
                          }
                         );
}

main();
