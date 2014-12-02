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
BEGIN { $INC{'ListQuery.pm'} ||= __FILE__ };

package ListQuery;
use POSIX;
use Encode;
use CGI qw(:standard);
use FindBin qw($Bin);
use lib "$Bin";
use ListUtils;
use ListPager;
use DatePeriod;
use HTML::Entities;

our @ISA = qw(Exporter);
our @EXPORT = qw(listApprovedArticles
                );

my @PERIOD_INDEXES = qw(last all day week month year lastweek lastmonth);
my %PERIOD_NAMES = ('last'      => '--最近--',
                    'day'       => '本日',
                    'week'      => '本週',
                    'lastweek'  => '前一週',
                    'month'     => '本月',
                    'lastmonth' => '前一個月',
                    'year'      => '今年',
                    'all'       => '--全部--');

my ($LIST, $PERIOD) = ('', '');
my ($INDEX, $LENGTH, $PAGER) = (0, 0, 0);

sub _getParams
{
    $LIST   = param('list')   || 'all';
    $PERIOD = param('period') || 'last';
    $INDEX  = param('index')  || 1;
    $LENGTH = param('length') || 15;

    $LIST   =~ s/[^\w\-]//g;
    $PERIOD =~ s/[^a-zA-Z]//g;
    $INDEX  =~ s/[^0-9]//g;
    $LENGTH =~ s/[^0-9]//g;

    $PERIOD = 'day'
        if (!defined($PERIOD_NAMES{$PERIOD}));

    if (isNumber($INDEX) && isNumber($LENGTH)) {
        if (isValidIndex($INDEX) && isValidLength($LENGTH)) {
            $PAGER = 1;
        }
    }
}

sub _setForm
{
    my $url = shift;
    my $sid = shift || '';
    my $result = <<EOF
<!-- auto-generated -->
<!--
<script type="text/javascript" src="/slist/js/widgets/thumbnail.js"></script>
-->
<form action="$url" method="post">
<input type="hidden" name="sid" value="$sid" />
發行期間：<select name="period">
EOF
;

    foreach (@PERIOD_INDEXES) {
        if ($PERIOD eq $_) {
            $result .= <<EOF
<option value="$_" selected="selected">$PERIOD_NAMES{$_}</option>
EOF
;
        }
        else {
            $result .= <<EOF
<option value="$_">$PERIOD_NAMES{$_}</option>
EOF
;
        }
    }

    $result .= <<EOF
</select>
電子報：<select name="list">
EOF
;
    if ($LIST eq 'all') {
        $result .= <<EOF
<option value="all" selected="selected">全部電子報</option>
EOF
;
    }
    else {
        $result .= <<EOF
<option value="all">全部電子報</option>
EOF
;
    }
    my @listnames = getListNames();
    foreach (@listnames) {
        my %fields = getListFields($_);
        next unless ($fields{'VISI'} eq '1');
        next unless ($fields{'PUBL'} eq '1');
        if ($LIST eq $_) {
            $result .= "<option value=\"$_\" selected=\"selected\">[$_] $fields{DESC}</option>\n";
        }
        else {
            $result .= "<option value=\"$_\">[$_] $fields{DESC}</option>\n";
        }
    }

    $result .= <<EOF
</select>
<input type="submit" value="查詢" />
</form>
<!-- auto-generated -->
EOF
;

    return $result;
}

sub _capitalWord
{
    my $subject = shift;
    my $result = <<EOF
<!--	<img src="/slist/images/newspaper_s.png" alt="newpaper_s" border="0" />-->
EOF
;
    my $capital = Encode::encode(
                      'utf-8',
                      substr(Encode::decode('utf-8', $subject), 0, 1)
                  );
    my $part = Encode::encode(
                   'utf-8',
                   substr(Encode::decode('utf-8', $subject), 1)
               );

    if (defined($capital) && ($capital ne '')) {
        $capital = encode_entities($capital, '<>&"');
        $result .=
            "<span style=\"color: blue; font-size: 200%;\">$capital</span>";
    }

    if (defined($part) && ($part ne '')) {
        $part = encode_entities($part, '<>&"');
        $result .=
            "<span style=\"font-size: 125%;\">$part</span>";
    }                                                                           

    return $result;
}

sub _listArticles
{
    my $url = shift || '';
    my $sid = shift || '';
    my $result = <<EOF
<br />
<table class="listquery" align="center" width="100%">
EOF
;

    my @articles = ();

    if ($LIST eq 'all') {
        foreach (getListNames()) {
            my %fields = getListFields($_);
            next unless ($fields{'VISI'} eq '1');
            next unless ($fields{'PUBL'} eq '1');
            push(@articles, getPublishArticles($_));
        }
    }
    else {
        my %fields = getListFields($LIST);
        push(@articles, getPublishArticles($LIST))
            if (($fields{'VISI'} eq '1') && ($fields{'PUBL'} eq '1'));
    }

    if ($PERIOD ne 'all') {
        my @buf = ();
        my ($low, $high) = getDateRange($PERIOD);
        my $ctime;
        foreach (@articles) {
            $ctime = ctimePublish($_);
            if (($ctime >= $low) && ($ctime < $high)) {
                push(@buf, $_);
            }
        }
        @articles = @buf;
    }

    @articles = sort {ctimePublish($b) <=> ctimePublish($a)} @articles;

    my ($subject, $time) = ('', '');
    if ($PAGER) {
        my $indexes = getMaxIndex($LENGTH, scalar(@articles));
        my $up  = getUpBound ($INDEX, $LENGTH, scalar(@articles));
        my $low = getLowBound($INDEX, $LENGTH, scalar(@articles));

        my @tmp = ();
        for (my $i = $low; $i <= $up; $i++) {
            last if (!($i < scalar(@articles)));
            push(@tmp, $articles[$i]);
        }
        @articles = @tmp;
        $result .= <<EOF
	<tr style="border: 0px;"><td colspan="2">
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
                $result .= <<EOF
		&nbsp;<a href="$url?sid=$sid&amp;period=$PERIOD&amp;list=$LIST&amp;index=$i&amp;length=$LENGTH">第$i頁</a>&nbsp;
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
		<td nowrap="nowrap" width="100%">電子報主旨</td>
		<td nowrap="nowrap">發行時間</td>
	</tr>
EOF
;
    my $j = -1;
    my $style;

    foreach (@articles) {
        $j++;
        $style = $j % 2;
        $time = strftime("%Y-%m-%d %H:%M:%S", localtime(ctimePublish($_)));
        $_ =~ s/(.*)\/(.*)/$1\/publish\/$2/;
        my ($l, $a) = ($1, $2);
        #$subject = _capitalWord(getDecodedSubjectFromFile("$SMARTLIST_PATH/$_"));
        my %fields = getListFields($1);
        $subject = getDecodedSubjectFromFile("$SMARTLIST_PATH/$_");
        $subject = encode_entities($subject, '<>&"');
        $result .= <<EOF
	<tr class="color$style" style="border: 1px solid; height: 48px;">
		<td style="text-align: left;" width="100%;">
			<span style="font-size: 90%;">
                	        [$fields{'NAME'}] $fields{'DESC'}
			</span>
			<br />
			<a href="viewer.cgi?sid=$sid&amp;list=$l&amp;article=$a">
				<span style="font-size: 120%;">
				$subject
				</span>
			</a>
		</td>
		<td nowrap="nowrap">$time</td>
	</tr>
EOF
;
    }

    $result .= <<EOF
</table>
EOF
;
    return $result;
}

sub listApprovedArticles
{
    # lyshie_20080620: shift may produce a false value => null string, number 0
    my $url = shift || '';
    my $sid = shift || '';

    _getParams();

    my $content = '';
    $content .= _setForm($url, $sid);
    $content .= _listArticles($url, $sid);

    return $content;
}
