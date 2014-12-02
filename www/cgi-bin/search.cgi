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
use ListSearch;
use ListPager;
use CGI qw(:standard);
use HTML::Entities;
use POSIX;
#
my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my ($list, $keyword) = ('', '');
my ($INDEX, $LENGTH, $PAGER) = (0, 0, 0);

sub getSearchContent
{
    my $listname = '';
    if ($list ne '') {
        my @lists = getListNames();
        foreach (@lists) {
            if ($list eq $_) {
                $listname = $list;
                last;
            }
        }
    }

    # generate keywords stack
    my @tmp = split(/\+/, $keyword);
    my @kws = ();
    foreach my $t (@tmp) {
        $t =~ s/[[:punct:]\s]//g;
        push(@kws, $t) if $t;
    }

    # normalize the keyword string
    my $keyword  = '';
    foreach (@kws) {
        $keyword .= "$_\+";
    }
    $keyword =~ s/\+$//;

    # get the search result
    my @match = ();
    foreach my $kw (@kws) {
        @match = searchSubject($kw, $listname, \@match);
    }

    # sort by date
    @match = reverse sort { ctimePublish($a) <=> ctimePublish($b) }
                          @match;

    my $result = <<EOF
<h2>查詢結果</h2>
<br />
EOF
;
    $listname = ($listname ne '') ? $listname : '全部電子報';

    if (@match > 0) {
        my $kw = encode_entities($keyword, '<>&"');
        my $count = @match;
        $result .= <<EOF
<code>
搜尋關鍵字 [$kw] 於電子報 [$listname] 當中，
找到 $count 筆符合的結果。
</code>
EOF
;

        $result .= <<EOF
<table class="light" width="100%" align="center">
EOF
;
        if ($PAGER) {
            my $indexes = getMaxIndex($LENGTH, scalar(@match));
            my $up  = getUpBound ($INDEX, $LENGTH, scalar(@match));
            my $low = getLowBound($INDEX, $LENGTH, scalar(@match));

            my @tmp = ();
            for (my $i = $low; $i <= $up; $i++) {
                last if (!($i < scalar(@match)));
                push(@tmp, $match[$i]);
            }
            @match = @tmp;

            $result .= <<EOF
        <tr style="border: 0px;"><td colspan="5">
EOF
;
            for (my $i = 1; $i <= $indexes; $i++) {
                if ($i == $INDEX) {
                    $result .= <<EOF
                    &nbsp;第$i頁&nbsp;
EOF
;
                }
                else {
                    my $kword = CGI::escape($keyword);
                    $result .= <<EOF
                    &nbsp;<a href="search.cgi?sid=$sid&amp;keyword=$kword&amp;index=$i&amp;length=$LENGTH">第$i頁</a>&nbsp;
EOF
;
                }
            }

            $result .= <<EOF
        </td></tr>
EOF
;
        }
        $result .= <<EOF
<tr class="listheader">
	<td>項次</td>
	<td>電子報</td>
	<td>發佈時間</td>
	<td>主旨</td>
	<td>線上閱覽</td>
</tr>
EOF
;
        my $index = getLowBound($INDEX, $LENGTH);
        foreach (@match) {
            $index++;
            my $style = $index % 2;
            my ($lst, $art) = split(/\//, $_);
            my $subject =
                getDecodedSubjectFromFile("$SMARTLIST_PATH/$lst/publish/$art");

            my @queue = ($subject);
            my @tokens = ();
            foreach my $kw (@kws) {
                my $kus = lc($kw);
                my $kuslen = length($kus);

                @tokens = ();
                foreach my $u (@queue) {
                    my $us = lc($u);
                    my $uslen = length($us);

                    my $i = 0;
                    while ($i < $uslen) {
                        my $idx = index($us, $kus, $i);

                        if ($idx != -1) {
                            my $t = substr($us, $i, $idx - $i);
                            push(@tokens, $t) if $t;

                            $t = substr($us, $idx, $kuslen);
                            push(@tokens, $t) if $t;

                            $i = $idx + $kuslen;
                        }
                        else {
                            my $t = substr($us, $i, $uslen);
                            push(@tokens, $t) if $t;

                            $i = $uslen;
                        }
                    }
                }

                @queue = @tokens;
            }

            my $us = $subject;
            $subject = '';
            my $i = 0;
            my $flag = 0;
            foreach my $t (@queue) {
                my $tus = lc($t);
                my $tlen = length($tus);
                $flag = 0;
                foreach my $kw (@kws) {
                    my $kus = lc($kw);
                    my $kuslen = length($kus);
                    if ($tus eq $kus) {
                        $subject .= "<span class=\"match\">" .
                            encode_entities(substr($us, $i, $kuslen), '<>&"') .
                            "</span>";
                        $i += $kuslen;
                        $flag = 1;
                        last;
                    }
                }
                if ($flag == 0) {
                    $subject .= encode_entities(substr($us, $i, $tlen), '<>&"');
                    $i += $tlen;
                }
            }

            my $time = strftime("%Y-%m-%d %H:%M:%S",
                                localtime(ctimePublish("$lst/$art"))
                               ) . "<br />" .
                       strftime("%Y-%m-%d %H:%M:%S",
                                localtime(ctimeApproved("$lst/$art"))
                               );

            $result .= <<EOF
<tr class="list color$style">
<td>$index</td>
<td>$lst</td>
<td>$time</td>
<td style="text-align: left;">$subject</td>
<td><a href="viewer.cgi?sid=$sid&amp;list=$lst&amp;article=$art">閱讀</a></td>
</tr>
EOF
;
        }
        $result .= '</table>';
    }
    else {
        $keyword = encode_entities($keyword, '<>&"');
        $result .= <<EOF
<code>
搜尋關鍵字 [$keyword] 於電子報 [$listname] 當中，
並未找到任何符合的結果。
</code>
EOF
;
    }

    $result .= <<EOF
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
    $list = defined(param('list')) ? param('list') : '';
    $list =~ s/[^\w\-]//g;

    $keyword = defined(param('keyword')) ? param('keyword') : '';
    $keyword =~ s/[<>\\\/'"%]//g;

    $INDEX  = param('index')  || 1;
    $LENGTH = param('length') || 10;

    $INDEX  =~ s/[^0-9]//g;
    $LENGTH =~ s/[^0-9]//g;

    if (isNumber($INDEX) && isNumber($LENGTH)) {
        if (isValidIndex($INDEX) && isValidLength($LENGTH)) {
            $PAGER = 1;
        }
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
                           'WIDGET_2' => getWidgetLatestArticles(),
                           'WIDGET_3' => getWidgetCalendar("list.cgi",
                                                           param('m'),
                                                           param('y')),
                           'CONTENT'  => getSearchContent(),
                          }
                         );
}

main();
