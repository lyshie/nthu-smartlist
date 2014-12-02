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
use ListLog;
use ourSession;
use ListUtils;
use CGI qw(:standard);
use POSIX;
use HTML::Entities;
#

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

my %names = ("LOGIN" => "登入",
             "LOGOUT" => "登出",
             "ARTICLE APPROVED" => "發行文章",
             "ARTICLE DISCARDED" => "刪除文章",
             "ARTICLE PUBLISHED" => "發佈文章",
             "ACTION" => "訂閱動作",
             "APPLY SETTINGS" => "套用設定",
             "UPLOAD DISTS" => "上傳訂戶清單",
             "UPDATE AUTO DISTS" => "更新自動訂戶清單",
             "WAIT FOR MODERATING" => "等待審查",
             "APPROVE OK" => "線上發行",
             "DISCARD OK" => "線上刪除",
            );

my %session_ids = ();

sub lightColor
{
    my $color = shift;
    $color = sprintf("%06s", $color);

    $color =~ m/(\w\w)(\w\w)(\w\w)/;
    my ($r, $g, $b) = (hex($1), hex($2), hex($3));
    $r = ($r % 56) + 200;
    $g = ($g % 56) + 200;
    $b = ($b % 56) + 200;

    return sprintf("%02x%02x%02x", $r, $g, $b);
}

sub getLogContent
{
    my $result = <<EOF
<script type="text/javascript" src="/slist/js/widgets/logquery.js"></script>
<h2>操作紀錄</h2>
<br />
作業階段編號：<select id="logquery">
<option value="all">全部</option>
<option value="none">其他</option>
#OPTIONS#
</select>
<br />
<br />
<table class="light" align="center" width="100%">
	<tr class="listheader">
		<td nowrap="nowrap">編號</td>
		<td nowrap="nowrap">時間</td>
<!--		<td nowrap="nowrap">程式名稱</td>	-->
		<td nowrap="nowrap">動作</td>
		<td nowrap="nowrap">內容</td>
	</tr>
EOF
;
    open(FH, "$SMARTLIST_PATH/$listname/log.smartlist");
    my @lines = <FH>;
    close(FH);

    my $j = 0;
    for (my $i = scalar(@lines); $i--; $i >= 0) {
        chomp($lines[$i]);
        $j++;
        my ($time, $prog, $token, $msg) = logParse($lines[$i]);
        next unless ($token eq 'LOGIN');
        $time = strftime("%Y-%m-%d %H:%M:%S", localtime($time));

        my $msgs = '';
        my $color = '373737';
        my $id = 'none';

        if ($token eq 'LOGIN') {
            my @a = split(/, /, $msg, 3);
            $msgs = "<ul><li>$a[0]</li><li>$a[1]</li><li>$a[2]</li></ul>";
            $color = substr($a[2], 0, 6);
            $id = $a[2]; 
        }
        elsif ($token eq 'LOGOUT') {
        #    my @a = split(/, /, $msg, 1);
        #    $msgs = "<ul><li>$a[0]</li></ul>";
        #    $color = substr($a[0], 0, 6);
        #    $id = $a[0]; 
        }
        elsif ($token eq 'APPLY SETTINGS') {
        #    my @a = split(/, /, $msg, 3);
        #    $msgs = "<ul><li>$a[0]</li></ul>";
        #    $color = substr($a[0], 0, 6);
        #    $id = $a[0]; 
        }
        elsif ($token eq 'WAIT FOR MODERATING') {
        #    my @a = split(/, /, $msg, 2);
        #    $a[1] = encode_entities($a[1], '<>&"');
        #    $msgs = "<ul><li>$a[0]</li><li>$a[1]</li></ul>";
        }
        elsif ($token eq 'ARTICLE DISCARDED') {
        #    my @a = split(/, /, $msg, 1);
        #    $msgs = "<ul><li>$a[0]</li></ul>";
        }
        elsif ($token eq 'ARTICLE APPROVED') {
        #    my @a = split(/, /, $msg, 1);
        #    $msgs = "<ul><li>$a[0]</li></ul>";
        }
        elsif ($token eq 'ARTICLE PUBLISHED') {
        #    my @a = split(/, /, $msg, 1);
        #    $msgs = "<ul><li>$a[0]</li></ul>";
        }
        elsif ($token eq 'DISCARD OK') {
        #    my @a = split(/, /, $msg, 2);
        #    $msgs = "<ul><li>$a[0]</li><li>$a[1]</li></ul>";
        #    $color = substr($a[0], 0, 6);
        #    $id = $a[0]; 
        }
        elsif ($token eq 'APPROVE OK') {
        #    my @a = split(/, /, $msg, 2);
        #    $msgs = "<ul><li>$a[0]</li><li>$a[1]</li></ul>";
        #    $color = substr($a[0], 0, 6);
        #    $id = $a[0]; 
        }
        elsif ($token eq 'ACTION') {
        #    my @a = split(/, /, $msg, 2);
        #    $msgs = "<ul><li>$a[0]</li><li>$a[1]</li></ul>";
        }
        elsif ($token eq 'UPLOAD DISTS') {
        #    my @a = split(/, /, $msg, 1);
        #    $msgs = "<ul><li>$a[0]</li></ul>";
        #    $color = substr($a[0], 0, 6);
        #    $id = $a[0]; 
        }
        elsif ($token eq 'UPDATE AUTO DISTS') {
        #    my @a = split(/, /, $msg, 2);
        #    $msgs = "<ul><li>$a[0]</li></ul>";
        #    $color = substr($a[0], 0, 6);
        #    $id = $a[0]; 
        }

        $session_ids{$id} = $j if ($id ne 'none');

        $color = lightColor($color);
        $token = $names{uc($token)};
        $result .= <<EOF
	<tr class="list" id="$id.$j">
		<td nowrap="nowrap">$j</td>
		<td nowrap="nowrap">$time</td>
<!--		<td nowrap="nowrap">$prog</td>	-->
		<td nowrap="nowrap">$token</td>
		<td style="background-color: #$color; text-align: left;">$msgs</td>
	</tr>
EOF
;
    }

    $result .= <<EOF
</table>
<br />
<div align="center">
	<a href="admin.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;

    my $options = '';
    my @keys = sort {$session_ids{$a} <=> $session_ids{$b}} keys(%session_ids);
    foreach (@keys) {
        my $color = substr($_, 0, 6);
        $color = lightColor($color);
        $options .= "<option style=\"background-color: #$color;\" value=\"$_\">$_</option>";
    }

    $result =~ s/#OPTIONS#/$options/mg;

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
                           'CONTENT'  => getLogContent(),
                          }
                         );
}

main();
