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
use Mail::Internet;
use MIME::Words qw(:all);
use Date::Parse;
use Email::Date;
use POSIX;
use HTML::Entities;
#
my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my $listname = '';

my ($d, $m, $y) = (0, 0, 0);

sub getListContent
{
    my %f = getListFields($listname);
    my $name = $f{'NAME'} ? "[$f{'NAME'}]" : '';
    my $result = <<EOF
<h2>$name $f{'DESC'} 典藏刊物</h2>
<br />
<table class="light" align="center" width="100%">
        <tr class="listheader">
                <td nowrap="nowrap">項次</td>
<!--		<td nowrap="nowrap">撰稿時間</td>	-->
                <td nowrap="nowrap">發行時間</td>
                <td nowrap="nowrap">電子報主旨</td>
                <td nowrap="nowrap">線上瀏覽</td>
        </tr>
EOF
;
    my @articles = ();

    if ($listname eq '') {
        my ($low, $high) = (0, 0);
        if ($d) {
            $low  = mktime(0, 0, 0, $d, $m - 1, $y - 1900);
            $high = mktime(0, 0, 0, $d + 1, $m - 1, $y - 1900);
        }
        else {
            # lyshie_20090120: fixed the time gap of month
            $low  = mktime(0, 0, 0, 1, $m - 1, $y - 1900);
            $high = mktime(0, 0, 0, 1, $m, $y - 1900);
        }
        my @tmps = ();

        # lyshie_20080623: check if publish
        foreach (getListNames()) {
            my %fields = getListFields($_);
            if (($fields{'VISI'} eq '1') && ($fields{'PUBL'} eq '1')) {
                push(@tmps, getPublishArticles($_));
            }
        }

        foreach my $tmp (@tmps) {
            my $t = ctimePublish($tmp);
            if (($t >= $low) && ($t < $high)) {
                push(@articles, $tmp);
            }
        }
    }
    else {
        # lyshie_20080623: check if publish
        my %fields = getListFields($listname);
        if (($fields{'VISI'} eq '1') && ($fields{'PUBL'} eq '1')) {
            @articles = getPublishArticles($listname);
        }
        else {
            @articles = ();
        }
    }
    my $index = 0;
    @articles = reverse sort { ctimePublish($a) <=> ctimePublish($b) }
                             @articles;
    foreach my $a (@articles) {
        my ($list, $article) = split(/\//, $a);

        open(FH, "$SMARTLIST_PATH/$list/publish/$article");
        my @msgs = ();
        
while (<FH>) {
            my $line = $_;
            chomp($line);
            last if ($line eq '');
            push(@msgs, $line);
        }
        close(FH);

        my $mail = Mail::Internet->new(\@msgs);
        my $MAIL_HEADER = $mail->head();
        my $subject = getDecodedSubject($MAIL_HEADER->get('subject'));
        chomp($subject);
        $subject = encode_entities($subject, '<>&"');
        my $composed_date = format_date(str2time($MAIL_HEADER->get('date')));
        my $approved_date =
            strftime("%Y-%m-%d %H:%M:%S", localtime(ctimePublish($a)));

        $index++;
        my $style = $index % 2;
        $result .= <<EOF
	<tr class="list color$style">
		<td nowrap="nowrap">$index</td>
<!--		<td nowrap="nowrap">$composed_date</td>	-->
		<td nowrap="nowrap">$approved_date</td>
		<td style="text-align: left;">$subject</td>
		<td nowrap="nowrap">
		<a href="viewer.cgi?sid=$sid&amp;list=$list&amp;article=$article">閱讀</a>
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

sub getParams
{
    $listname = defined(param('list')) ? param('list') : '';
    $listname =~ s/[^\w\-]//g;

    $d = defined(param('d')) ? param('d') : 0;
    $m = defined(param('m')) ? param('m') : 0;
    $y = defined(param('y')) ? param('y') : 0;

    $d =~ s/[^0-9]//g;
    $m =~ s/[^0-9]//g;
    $y =~ s/[^0-9]//g;
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
                           'CONTENT'  => getListContent(),
                          }
                         );
}

main();
