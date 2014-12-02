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
use ListLog;
use ourSession;
use CGI qw(:standard);
use File::Basename;
use Unix::Syslog qw(:macros :subs);
use Encode;
#

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

my ($maintainer, $organization, $phone, $visible, $publish, $url) =
    ('', '', '', '', '', '');
my $action = '';

my $CATALOG = "$SMARTLIST_PATH/www/htdocs/catalog";

sub getSettingsContent
{
    my %fields = getListFields($listname);

    my ($visible_t, $visible_f) = ('', '');
    my ($publish_t, $publish_f) = ('', '');

    if ($fields{'VISI'} eq '1') {
        $visible_t = ' selected="selected"';
    }
    else {
        $visible_f = ' selected="selected"';
    }

    if ($fields{'PUBL'} eq '1') {
        $publish_t = ' selected="selected"';
    }
    else {
        $publish_f = ' selected="selected"';
    }

    #
    my $url_orig = '';
    if (-f "$CATALOG/$listname.html") {
        open(FH, "$CATALOG/$listname.html");
        $url_orig = <FH>;
        chomp($url_orig);
        $url_orig =~ s/.*url=(.+)".*/$1/g;
        close(FH);

        $url_orig = $url_orig ? $url_orig : '';
    }
    #

    my $result = <<EOF
<h2>設定電子報屬性</h2>
<br />
<form action="settings.cgi" method="post">
<input type="hidden" name="sid" value="$sid" />
<table class="light" align="center">
	<tr>
		<td class="lightheader">管理者：</td>
		<td class="light">
		<input disabled="disabled" type="text" name="maintainer" value="$fields{'MAIN'}" />
		</td>
	</tr>
	<tr>
		<td class="lightheader">管理單位：</td>
		<td class="light">
		<input disabled="disabled" type="text" name="organization" value="$fields{'ORGA'}" />
		</td>
	</tr>
	<tr>
		<td class="lightheader">連絡電話：</td>
		<td class="light">
		<input type="text" name="phone" value="$fields{'PHON'}" />
		</td>
	</tr>
        <tr>
                <td class="lightheader">網頁介紹：</td>
                <td class="light">
                <input type="text" name="url" value="$url_orig" />
                </td>
        </tr>
	<tr>
		<td class="lightheader">可見度：</td>
		<td class="light">
			<select name="visible">
				<option value="1"$visible_t>可見</option>
				<option value="0"$visible_f>不可見</option>
			</select>
		</td>
	</tr>
	<tr>
		<td class="lightheader">公開度：</td>
		<td class="light">
			<select name="publish">
				<option value="1"$publish_t>可公開</option>
				<option value="0"$publish_f>不可公開</option>
			</select>
		</td>
	</tr>
	<tr>
		<td class="light" colspan="2" style="text-align: center;">
			<input type="submit" name="action" value="變更設定" />
		</td>
	</tr>
</table>
</form>
<code>
1. 網頁介紹：您可輸入介紹該電子報的網頁連結；
2. 可見度：您可選擇「可見」或「不可見」來決定是否可以使用該電子報；
3. 公開度：您可選擇「可公開」或「不可公開」來決定是否提供使用者線上
　 瀏覽您發行過的電子報刊物與 RSS 訂閱、關鍵字搜尋等功能。

選擇公開電子報的優點：
　　* 您所發行的電子報內容將收錄於本網站上供讀者閱覽；
　　* 系統將自動彙整您所發行的電子報主旨 (含原文 URL) 納入一週電子報摘要
　　　[digest] 中，每星期自動寄出，以方便讀者訂閱及掌握全校資訊；
　　* 讀者可透過 RSS 及 OPML 功能自行閱讀電子報。

如果您的電子報屬性不適宜公開在網站上供任何人閱讀，請勿公開電子報。
</code>
<br />
<div align="center">
<a href="admin.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub setCheck
{
    $maintainer   =~ s/[[:punct:]\n\r]//g;
    $maintainer   = Encode::encode('utf-8', 
                        substr(Encode::decode('utf-8', $maintainer), 0, 12));
    $organization =~ s/[[:punct:]\n\r]//g;
    $organization = Encode::encode('utf-8',
                        substr(Encode::decode('utf-8', $organization), 0, 12));
    $phone        =~ s/[^\d\-]//g;
    $phone        = Encode::encode('utf-8',
                        substr(Encode::decode('utf-8', $phone), 0, 12));

    $visible      = ($visible eq '1') ? '1' : '0';
    $publish      = ($publish eq '1') ? '1' : '0';

    $url          = Encode::encode('utf-8',
                        substr(Encode::decode('utf-8', $url), 0, 64));
}

sub getParams
{
    $maintainer   = param('maintainer');
    $maintainer   = defined(param('maintainer'))   ? param('maintainer')   : '';
    $organization = param('organization');
    $organization = defined(param('organization')) ? param('organization') : '';
    $phone        = param('phone');
    $phone        = defined(param('phone'))        ? param('phone')        : '';
    $visible      = param('visible');
    $visible      = defined(param('visible'))      ? param('visible')      : '';
    $publish      = param('publish');
    $publish      = defined(param('publish'))      ? param('publish')      : '';
    $action       = param('action');
    $action       = defined(param('action'))       ? param('action')       : '';

    $url          = param('url');
    $url          = defined(param('url'))          ? param('url')          : '';

    setCheck();
}

sub applySettings
{
    my %fields = getListFields($listname);

    #$fields{'MAIN'} = $maintainer;
    #$fields{'ORGA'} = $organization;
    $fields{'PHON'} = $phone;
    $fields{'VISI'} = $visible;
    $fields{'PUBL'} = $publish;

    setListFields(\%fields);

    #
    if ($url) {
        open(FH, ">$CATALOG/$listname.html");
        print FH qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh-tw" lang="zh-tw" dir="ltr"><head>  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />  <meta http-equiv="Refresh" content="0; url=$url" />  <title>國立清華大學電子報系統</title></head><body></body></html>};
        close(FH);
    }
    else {
        unlink("$CATALOG/$listname.html");
    }
    #

    syslog(LOG_INFO,
           "Apply settings. (sid=%s)",
           $sid,
          );

    logToList($listname,
              "[%s] APPLY SETTINGS (%s)",
              basename($0),
              $sid
             );
}

sub main
{
    openlog(basename($0), LOG_PID, LOG_LOCAL5);

    getParams();

    if ($action ne '') {
        applySettings();
    }

    print header(-charset=>'utf-8');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getAdminMenu($sid),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetLatestArticles(),
                           'WIDGET_3' => getWidgetSession(),
                           'CONTENT'  => getSettingsContent(),
                          }
                         );

    closelog();
}

main();
