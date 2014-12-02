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

my $MODERATE_MSG_FILE = "$Bin/moderate.txt";

sub getModerateContent
{
    # lyshie_20090401: get admin messages
    my $moderate_msg = "";
    if (-f "$MODERATE_MSG_FILE") {
        open(FH, "$MODERATE_MSG_FILE");
        while (<FH>) {
            $moderate_msg .= $_;
        }
        close(FH);
    }

    my $result = <<EOF
<h2>審查發行電子報</h2>
<br />
<code>
$moderate_msg
</code>
<form name="moderate" action="moderate_s.cgi" method="post">
<input type="hidden" name="sid" value="$sid" />
<input type="hidden" name="action" />
<table class="light" align="center" width="100%">
	<tr class="list">
		<td colspan="7">
			<input type="button" name="action_a" value="發行電子報" onclick="SelectArticles('approve');" />
			<input type="button" name="action_d" value="刪除電子報" onclick="SelectArticles('discard');" />
		</td>
	</tr>
        <tr class="listheader">
                <td nowrap="nowrap">項次</td>
		<td nowrap="nowrap">
		發行<br />
		<input type="button" value="全選" onclick="CheckAll(this.form, 'approve');" />
		</td>
		<td nowrap="nowrap">
		刪除<br />
		<input type="button" value="全選" onclick="CheckAll(this.form, 'discard');" />
		</td>
		<td nowrap="nowrap">電子報編號</td>
                <td nowrap="nowrap">投稿時間/審查時間</td>
                <td>電子報主旨</td>
                <td nowrap="nowrap">線上瀏覽</td>
        </tr>
EOF
;
    my @articles = getModerateArticles($listname);
    my $index = 0;
    @articles = reverse sort { ctimeModerate($a) <=> ctimeModerate($b) }
                             @articles;
    foreach my $a (@articles) {
        my ($list, $article) = split(/\//, $a);

        open(FH, "$SMARTLIST_PATH/$listname/moderate/$article");
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
        my $composed_date =
            strftime("%Y-%m-%d %H:%M:%S",
                     localtime(str2time($MAIL_HEADER->get('date')))
                    );
        my $moderate_date =
            strftime("%Y-%m-%d %H:%M:%S", localtime(ctimeModerate($a)));

        $index++;
        my $style = $index % 2;
        $result .= <<EOF
	<tr class="list color$style">
		<td nowrap="nowrap">$index</td>
		<td><input type="checkbox" id="approve" name="approve" value="$article" /></td>
		<td><input type="checkbox" id="discard" name="discard" value="$article" /></td>
		<td nowrap="nowrap">$article</td>
		<td nowrap="nowrap">$composed_date<br />$moderate_date</td>
		<td style="text-align: left;">$subject</td>
		<td nowrap="nowrap">
		<a href="viewer_s.cgi?sid=$sid&amp;list=$listname&amp;article=$article&amp;mode=moderate">閱讀</a>
		</td>
	</tr>
EOF
;
    }
    

    $result .= <<EOF
	<tr class="list">
		<td colspan="7">
			<input type="button" name="action_a" value="發行電子報" onclick="SelectArticles('approve');" />
			<input type="button" name="action_d" value="刪除電子報" onclick="SelectArticles('discard');" />
		</td>
	</tr>
</table>
</form>
<br />
<div align="center">
<a href="admin.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub main
{
    print header(-charset=>'utf-8');
    print templateReplace('moderate.ht',
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
                           'CONTENT'  => getModerateContent(),
                          }
                         );
}

main();
