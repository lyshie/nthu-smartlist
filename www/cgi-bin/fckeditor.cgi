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
use MIME::Lite;
use MIME::Words qw(:all);
use Digest::SHA qw(sha1_hex);
use lib "$SMARTLIST_PATH/www/htdocs/fckeditor";
require "fckeditor.pl";
#

my ($listname, $sid) = sessionCheck();

my ($SUBJECT, $HTML, $PLAIN) = ('', '', '');
my ($SUBMIT, $ACTION)        = ('', '');
my $RESULT                   = '';
my $FCKEDITOR                = "$SMARTLIST_PATH/www/cgi-bin/fckeditor";
my $INSTANCE                 = sha1_hex("$listname\n$sid") || 'slist';

sub readMail
{
    my $file_subject   = "$FCKEDITOR/$listname.subject";
    my $file_htmlpart  = "$FCKEDITOR/$listname.htmlpart";
    my $file_plainpart = "$FCKEDITOR/$listname.plainpart";

    $SUBJECT = "";
    $HTML    = "";
    $PLAIN   = "";

    if (-f $file_subject) {
        open(FH, "$file_subject");
        $SUBJECT = <FH>;
        close(FH);
    }

    if (-f $file_htmlpart) {
        open(FH, "$file_htmlpart");
        while (<FH>) {
           $HTML .= $_; 
        }
        close(FH);
    }

    if (-f $file_plainpart) {
        open(FH, "$file_plainpart");
        while (<FH>) {
            $PLAIN .= $_;
        }
        close(FH);
    }
}

sub saveMail
{
    my $file_subject   = "$FCKEDITOR/$listname.subject";
    my $file_htmlpart  = "$FCKEDITOR/$listname.htmlpart";
    my $file_plainpart = "$FCKEDITOR/$listname.plainpart";

    open(FH, ">$file_subject");
    print FH $SUBJECT;
    close(FH);

    open(FH, ">$file_htmlpart");
    print FH $HTML;
    close(FH);

    open(FH, ">$file_plainpart");
    print FH $PLAIN;
    close(FH);

    my $now = localtime(time());
    $RESULT = qq{<code>$now - 已儲存信件。</code>};
}

sub sendMail
{
    my $msg = MIME::Lite->new(
                  From     => getListMaintainer($listname),
                  To       => "$listname\@" . getListDomain(),
                  Subject  => encode_mimeword($SUBJECT, 'b', 'UTF-8'),
                  Type     => 'multipart/alternative',
              ); 

    my $plain_part = MIME::Lite->new(
        Type => 'TEXT',
        Data => $PLAIN,
        Encoding => 'base64',
    );
    $plain_part->attr('content-type.charset' => 'UTF-8');

    my $html_part = MIME::Lite->new(
        Type => 'text/html',
        Data => $HTML,
        Encoding => 'base64',
    );
    $html_part->attr('content-type.charset' => 'UTF-8');

    $msg->attach($plain_part);
    $msg->attach($html_part);

    $msg->send();

    my $now = localtime(time());
    $RESULT = qq{<code>$now - 已寄出信件，您可以進行審查。</code>};
}

sub getFCKContent
{
    FCKeditor($INSTANCE, $HTML);
    my $fckeditor = CreateHtml();

    my $result = <<EOF
<h2>編輯電子報</h2>
<br />
<!-- lyshie_20090327: begin result -->
$RESULT
<!-- lyshie_20090327: end result -->
<form action="fckeditor.cgi" method="post">
<input type="hidden" name="sid" value="$sid" />
<table class="light" width="90%" align="center">
	<tr class="listheader">
		<td>電子報主旨</td>
	</tr>
	<tr class="list">
		<td><input type="text" name="subject" size="32" value="$SUBJECT" /></td>	
	</tr>
	<tr class="listheader">
		<td>HTML 內容</td>
	</tr>
	<tr class="list">
		<td>$fckeditor</td>
	</tr>
	<tr class="listheader">
		<td>純文字內容</td>
	</tr>
	<tr class="list">
		<td><textarea name="plain" style="width: 99%;" rows="10" cols="48">$PLAIN</textarea></td>	
	</tr>
	<tr class="list">
		<td>
			<input type="submit" name="submit" value="儲存" />
			<input type="submit" name="action" value="寄出" />
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

sub getParams
{
    $SUBJECT = param('subject') || '無標題';
    $SUBJECT =~ s/[\n\r\t]//g;
    $HTML    = param($INSTANCE) || '';
    $PLAIN   = param('plain')   || '';
    $ACTION  = param('action')  || '';
    $SUBMIT  = param('submit')  || '';
}

sub main
{
    getParams();

    if (!$ACTION && !$SUBMIT) {
        readMail();
    }

    if ($ACTION) {
        sendMail();
    }

    if ($SUBMIT) {
        saveMail();
    }

    print header(-charset=>'utf-8');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getAdminMenu($sid),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetSession(),
                           'WIDGET_3' => getNull(),
                           'CONTENT'  => getFCKContent(),
                          }
                         );
}

main();
