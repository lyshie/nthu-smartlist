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
umask(0000);
use FindBin qw($Bin);
use lib "$Bin";
use ListUtils;
use Mail::Internet;
use HTML::Entities;
use POSIX qw(strftime mktime);
use FindBin qw($Bin);
use MIME::Lite;
use MIME::Words qw(:all);
use Data::UUID;
use Email::Date;
use File::Basename;
#
my $HTML_PATH = "$SMARTLIST_PATH/www/htdocs/digest";
my $TEXT_PATH = "$SMARTLIST_PATH/www/htdocs/digest";
my $URL       = "http://" . getListDomain();
my $FLIST     = "$SMARTLIST_PATH/.bin/flist";


my $TODAY   = 0;  # timestamp for Today
my $HTML    = ''; # the html part
my $TEXT    = ''; # the text part
my $TITLE   = ''; # subject
my $UUID    = ''; # unique id
my $MESSAGE = ''; # the whole mail message
my $TO      = '一週電子報摘要';
my $TO_ADDR = '<digest@' . getListDomain() . '>';
my $PERIOD  = 7;  # default is 7 days a week

sub HTMLBegin
{
    $HTML = ''; # clear 
    $HTML = <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<meta name="description" content="" />
	<meta name="keywords" content="" />

	<title>$TITLE</title>

	<style type="text/css">
	body, td {
	    font-size: 11pt;
	    font-family: tahoma, arial;
	    margin-top: 32px;
	}

	table.light {
	    background-color: #f6f6f4;
	    border: 1px #000000 solid;
	    border-collapse: collapse;
	    border-spacing: 0px;
	}

	tr.listheader > td {
	    text-align: center;
	    background-color: #99CCCC;
	    border: 1px #000000 solid;
	    font-weight: bold;
	    color: #404040;
	    padding: 4px;
	}

	tr.list > td {
	    text-align: center;
	    border-bottom: 1px #6699CC dotted;
	    border: 1px #000000 solid;
	    padding-top: 4px;
	    padding-bottom: 4px;
	    padding-left: 4px;
	    padding-right: 4px; 
	    padding: 4px;
	}

	tr.list {
	    background-color: rgb(255, 255, 255);
	}

	tr.list:hover {
	    background-color: #fcfccc;
	}

	a {
	    text-decoration: none;
	}

	a:hover {
	    color: rgb(255, 0, 0);
	}
	</style>
</head>
<body style="font-size: 11pt; font-family: tahoma, arial; margin-top: 32px;">
<div align="center">
<h2>$TITLE</h2>
<h5>
本信件由 [digest] 一週電子報摘要 自動產生，
如欲取消訂閱\請至 <a href="$URL/slist/">$URL/slist/</a>。
</h5>
<table class="light" border="1" width="75%" style="background-color: #f6f6f4; border: 1px #000000 solid; border-collapse: collapse; border-spacing: 0px;">
<tr class="listheader" style="text-align: center; background-color: #99CCCC; border: 1px #000000 solid; font-weight: bold; color: #404040; padding: 4px;">
	<td>電子報名稱</td>
	<td>發行日期</td>
	<td>文章主題</td>
</tr>
EOF
;

##########
    $TEXT = <<EOF
$TITLE
EOF
;
}

sub HTMLAddItem
{
    my ($list, $article, $subject, $approved_date) = @_; 
    my $subject_enc = encode_entities("$subject", '<>&"');
    my $link ="$URL/slist/cgi-bin/viewer.cgi?article=$article&amp;list=$list";
    my $date = strftime("%F", localtime($approved_date));
    my $item = <<EOF
<tr class="list">
	<td nowrap="nowrap" style="text-align: center;">$date</td>
	<td style="text-align: left;"><a href="$link">$subject_enc</a></td>
</tr>
EOF
;
    $HTML .= $item; 
##########
    $item = <<EOF
  * $subject
    [$date]
    $link
EOF
;
    $TEXT .= $item;
}

sub HTMLEnd
{
    my $list = shift;
    my $end = <<EOF
</table>
<h5>
本信件由 [digest] 一週電子報摘要 自動產生，
如欲取消訂閱\請至 <a href="$URL/slist/">$URL/slist/</a>。
</h5>
</div>
</body>
</html>
EOF
;
    $HTML .= $end; 
    #umask(0000);
    open(FH, ">$HTML_PATH/digest.html");
    print FH $HTML;
    close(FH);
##########

    $end = <<EOF


-- 
本信件由 [digest] 一週電子報摘要 自動產生，
如欲取消訂閱\請至 $URL/slist/。
EOF
;
    $TEXT .= $end;
    #umask(0000);
    open(FH, ">$TEXT_PATH/digest.txt");
    print FH $TEXT;
    close(FH);
}

sub sender 
{
    my $list = shift;

    my $msg = MIME::Lite->build(
        From      => 'slist@' . getListDomain(),
        To        => encode_mimeword($TO, 'b', 'UTF-8') . " $TO_ADDR",
        Subject   => encode_mimeword($TITLE, 'b', 'UTF-8'), 
        Type      => 'multipart/alternative',
        Datestamp => '',
    );

    $msg->replace('x-uuid' => $UUID);  # for security reason
    $msg->replace('date' => format_date());

    my ($HTML, $TEXT) = ('', '');

    open(HTML, "$HTML_PATH/digest.html");
    while (<HTML>) {
        $HTML .= $_;
    }
    close(HTML);

    my $htmlpart = MIME::Lite->new(Type => 'text/html',
                                   Encoding => 'base64',
                                   Data => $HTML
                                  );
    $htmlpart->attr('content-type.charset' => 'UTF-8');
    $htmlpart->scrub(['x-mailer', 'mime-version', 'date']);

    open(TEXT, "$TEXT_PATH/digest.txt");
    while (<TEXT>) {
        $TEXT .= $_;
    }
    close(TEXT);

    my $textpart = MIME::Lite->new(Type => 'TEXT',
                                   Encoding => 'base64',
                                   Data => $TEXT
                                  );
    $textpart->attr('content-type.charset' => 'UTF-8');
    $textpart->scrub(['x-mailer', 'mime-version', 'date']);

    $msg->attach($textpart);
    $msg->attach($htmlpart);

    $msg->scrub(["content-disposition", "x-mailer"]);
    $msg->replace('x-mailer' => basename($0));

    $MESSAGE = $msg->as_string();
}

sub getArticleByDay
{
    my @lists = getListNames();
    my @articles = ();

    my $subject = '';
    my $approved_date = '';

    HTMLBegin();

    foreach my $list (@lists) {
        next if ($list eq 'digest');
        # lyshie_20080326: the list should !hidden and public
        my %fields = getListFields($list);
        next if (($fields{'VISI'} eq '0') || ($fields{'PUBL'} eq '0'));

        @articles = reverse sort { ctimePublish($a) <=> ctimePublish($b) }
                                 getPublishArticles($list);

        my @articles_week = ();

        foreach my $a (@articles) {

            my ($l, $article) = split(/\//, $a);
            my $file = "$SMARTLIST_PATH/$l/publish/$article";

            open(FH, "$file");
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

            $subject = getDecodedSubject($MAIL_HEADER->get('subject'));
            $approved_date = ctimePublish($a);

            my ($sec,$min,$hour,$mday,$mon,$year) = localtime($approved_date);

            my $date = mktime(0, 0, 0, $mday, $mon, $year); 

            if (($TODAY - $date) < 86400 * $PERIOD) {
                #printf("%s %s\n", $subject, $approved_date);
                my %tmp = ('list'          => $list,
                           'article'       => $article,
                           'subject'       => $subject,
                           'approved_date' => $approved_date
                          );
                push(@articles_week, \%tmp);
            }
        }

        my $count = @articles_week;
        if ($count > 0) {
            my $description = $fields{'DESC'};

            $count++;
            $HTML .= <<HTML
<tr class="list" style="background-color: #f6f6f4; font-size: 11pt;">
	<td rowspan="$count" colspan="1" nowrap="nowrap" style="text-align: center;">[$list]<br />$description</td>
</tr>
HTML
;
            $TEXT .= <<TEXT

[$list] $description
TEXT
;
        }

        foreach my $ref (@articles_week) {
            my %tmp = %$ref;
            HTMLAddItem($tmp{'list'},
                        $tmp{'article'},
                        $tmp{'subject'},
                        $tmp{'approved_date'}
                       );
        }
    }
    HTMLEnd();
    sender();
}

sub approve_digest
{
    open(FLIST, "|$FLIST digest")
        || die "Can't fork: $!\n";
    print FLIST $MESSAGE;
    close FLIST;
}

sub getPeriod
{
    my $tmp = $ARGV[0];
    return unless defined($tmp);

    $tmp =~ s/\D//g;
    if ($tmp ne '') {
        $PERIOD = $tmp;
    }
}

sub main
{
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime();

    $TODAY = mktime(0, 0, 0, $mday, $mon, $year);

    getPeriod();

    $TITLE = "一週電子報摘要" . " (" .
             strftime("%F", localtime($TODAY - 86400 * ($PERIOD - 1))) . 
             " ~ " . 
             strftime("%F", localtime($TODAY)) .
             ")";

    my $ug = new Data::UUID;
    $UUID = $ug->create_hex();

    getArticleByDay();

    approve_digest();  # the last action is approving it!!! 
}

main();
