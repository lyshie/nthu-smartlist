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
use Mail::Internet;
use MIME::Words qw(:all);
use Date::Parse;
use Email::Date;
use POSIX;
use HTML::Entities;
#

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

sub getApprovedContent
{
    my $result = <<EOF
<h2>已發行刊物記錄</h2>
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
    my @articles = getApprovedArticles($listname);
    my $index = 0;
    @articles = reverse sort { ctimeApproved($a) <=> ctimeApproved($b) }
                             @articles;
    foreach my $a (@articles) {
        my ($list, $article) = split(/\//, $a);

        open(FH, "$SMARTLIST_PATH/$listname/approved/$article");
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
            strftime("%Y-%m-%d %H:%M:%S", localtime(ctimeApproved($a)));

        $index++;
        my $style = $index % 2;
        $result .= <<EOF
	<tr class="list color$style">
		<td nowrap="nowrap">$index</td>
<!--		<td nowrap="nowrap">$composed_date</td>	-->
		<td nowrap="nowrap">$approved_date</td>
		<td style="text-align: left;">$subject</td>
		<td nowrap="nowrap">
		<a href="viewer_s.cgi?sid=$sid&amp;list=$listname&amp;article=$article">閱讀</a>
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
                           'MENU'     => getAdminMenu($sid),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetLatestArticles(),
                           'WIDGET_3' => getWidgetContainer(
                                             getWidgetCalendar("list.cgi",
                                                               param('m'),
                                                               param('y')),
                                             getWidgetSession(),
                                         ),
                           'CONTENT'  => getApprovedContent(),
                          }
                         );
}

main();
