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
use Encode;
#
package ListTemplate;
BEGIN { $INC{'ListTemplate.pm'} ||= __FILE__ };

use Mail::Header;
use Mail::Internet;
use MIME::Words qw(:all);
use FindBin qw($Bin);
use lib "$Bin";
use ListUtils;
use ourSession;
use Mail::POP3Client;
use CGI qw(:standard);
use HTML::Entities;
use Socket;

# get the parameters before utf-8 encoding
my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my $keyword = param('keyword') || '';
$keyword =~ s/[<>\\\/'"%]//g;

our @ISA = qw(Exporter);
our @EXPORT = qw(templateReplace
                 getRedirectMeta
                 getDefaultMenu
                 getAdminMenu
                 getDefaultTitle
                 getDefaultTopic
                 getWidgetSearch
                 getNull
                 getWidgetLatestArticles
                 getWidgetArticles
                 getWidgetClientInfo
                 getWidgetSession
                 getWidgetCalendar
                 str_replace
                 getComboAcceptHosts
                 checkAcceptHosts
                 getWidgetValidation
                 getWidgetContainer
                 getWidgetCWB
                 getWidgetNTHUNews
                );

our $TEMPLATE_PATH   = "$Bin/templates";

sub str_replace {
    my $replace_this = shift;
    my $with_this  = shift; 
    my $string   = shift;

    my $length = length($string);
    my $target = length($replace_this);

    for(my $i=0; $i<$length - $target + 1; $i++) {
        if(substr($string,$i,$target) eq $replace_this) {
            $string = substr($string,0,$i) . $with_this . substr($string,$i+$target);
            #return $string; #Comment this if you what a global replace
        }
    }

    return $string;
}

sub templateReplace
{
    my $template = shift;
    my $replaces = shift;

    my $result = '';
    if (-f "$TEMPLATE_PATH/$template") {
        open(FH, "$TEMPLATE_PATH/$template");
        while (<FH>) {
            $result .= $_;
        }
        close(FH);
    }

    foreach my $replace (keys(%$replaces)) {
        my $content = $replaces->{$replace};
        $replace = '[% ' . uc($replace) . ' %]';
        $result = str_replace($replace, $content, $result);
    }

    return $result;
}

sub checkAcceptHosts
{
    my ($email, $password) = @_;

    return 0 if (($email eq '') || ($password eq ''));
    my ($username, $host) = ('', '');
    ($username, $host) = split(/\@/, $email, 2);
    $host = lc($host);

    my $status = 0;
    foreach (@ACCEPT_HOSTS) {
        if ($_ eq $host) {
            my $pop = new Mail::POP3Client(HOST => $ACCEPT_POP3_HOSTS{$host},
                                           TIMEOUT => 10 
                                          );
            $pop->User($username);
            $pop->Pass($password);
            $status = $pop->Connect(); #&& $pop->Login();
            $pop->Close();
            return $status;
        }
    }
    return $status;
}

sub getComboAcceptHosts
{
    my $result = <<EOF
	<!-- auto-generated -->
	<select name="host">
EOF
;
    foreach (@ACCEPT_HOSTS) {
        $result .= <<EOF
	<option value="$_">$_</option>
EOF
;
    }

    $result .= <<EOF
	</select>
	<!-- auto-generated -->
EOF
;
    return $result;
}

sub getRedirectMeta
{
    my ($url, $timeout) = @_;
    $url = defined($url) ? $url : '';
    $timeout = defined($timeout) ? $timeout : 0;

    my $result = '';

    if ($url ne '') {
        $result = <<EOF
	<meta http-equiv="refresh" content="$timeout;URL=$url" />
EOF
;
    }

    return $result;
}

sub getDefaultTitle
{
    return '國立清華大學電子報';
}

sub getDefaultTopic
{
    return '<h1><img src="/slist/images/newspaper.png" border="0" align="top" alt="newspaper" />&nbsp;' . "<a style=\"color: #fff; font-weight: bold;\" href=\"index.cgi?sid=$sid\">" . '國立清華大學電子報</a></h1>';
}

sub getDefaultMenu
{
    my $menu = <<EOF
<!-- auto-generated -->
	<li><a href="index.cgi?sid=$sid">電子報首頁 (Home)</a></li>
	<li><a href="archives.cgi?sid=$sid">電子報全覽 (Archives)</a></li>
	<li><a href="reader.cgi?sid=$sid">訂閱戶專區 (Reader)</a></li>
	<li><a href="admin.cgi?sid=$sid">管理者專區 (Admin)</a></li>
	<li><a href="stat.cgi?sid=$sid">統計資料 (Statistics)</a></li>
	<li><a href="help.cgi?sid=$sid">操作說明 (Help)</a></li>
	<li><a href="contact.cgi?sid=$sid">連絡我們 (Contact Us)</a></li>
<!-- auto-generated -->
EOF
;
    return $menu;
}

sub getWidgetSearch
{
    my $result = <<EOF
<!-- auto-generated -->
<script type="text/javascript" src="/slist/js/widgets/searchtips.js"></script>
<div class="widget">
<h4>主旨關鍵字搜尋<br />(Keyword Search)</h4>
<form action="search.cgi" method="post">
<input type="hidden" name="sid" value="$sid" />
<table border="0" align="center" style="width: 120px;">
<tr><td>
<input type="text" id="searchtips" name="keyword" value="$keyword" style="width: 110px;" /><br />
<select name="list" style="width: 120px;">
<option value="all" selected="selected">全部電子報 (All)</option>
EOF
;
    my @lists = getListNames();
    foreach my $list (@lists) {
        my %fields = getListFields($list);
        next unless ($fields{'VISI'} eq '1');
        next unless ($fields{'PUBL'} eq '1');
        $result .= "<option value=\"$list\">[$list] $fields{'DESC'}</option>";
    }

    $result .= <<EOF
</select>
<input type="submit" value="查詢 (Search)" />
</td></tr>
</table>
</form>
</div>
<!-- auto-generated -->
EOF
;
    return $result;
}

sub getNull
{
    my $result = <<EOF
<!-- auto-generated -->
<!-- null -->
<!-- auto-generated -->
EOF
;
}

sub getWidgetLatestArticles
{
    my @articles = getLatestPublishArticles();

    # if no articles then return
    return "" unless (@articles);

    my $table = '';
    my $result = <<EOF
<div class="widget">
<h4>最新電子報</h4>
EOF
;
    my $index = 0;
    foreach (@articles) {
        my ($list, $article) = split(/\//, $_);
        next if ($list eq 'digest');

        my %fields = getListFields($list);
        next unless ($fields{'VISI'} eq '1');
        next unless ($fields{'PUBL'} eq '1');

        my $file = "$SMARTLIST_PATH/$list/publish/$article";

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
        my $subject = getDecodedSubject($MAIL_HEADER->get('subject'));
        chomp($subject);
        $subject = encode_entities($subject, '<>&"');

        %fields = getListFields($list);
        $index++;
        $table .= <<EOF
	<tr>
		<td valign="top">$index.</td>
		<td align="left" style="text-align: left;">
		<a href="viewer.cgi?sid=$sid&amp;list=$list&amp;article=$article" title="[$list] $fields{'DESC'}">$subject</a>
		</td>
	</tr>
EOF
;
        if ($index > 4) {
            last;
        }
    }

    if ($table ne '') {
        $result .= <<EOF
<table>
$table
</table>
EOF
    }

    $result .= <<EOF
</div>
EOF
;
    return $result;
}

sub getWidgetArticles
{
    my $listname = param('list') || return '';

    my %fields = getListFields($listname);

    return "" unless ($fields{'VISI'} eq '1');
    return "" unless ($fields{'PUBL'} eq '1');

    my $table = '';
    my $result = <<EOF
<div class="widget">
<h4>電子報 [$listname]</h4>
EOF
;
    my @articles = getPublishArticles($listname);

    @articles = reverse sort { ctimePublish($a) <=> ctimePublish($b) }
                    @articles;

    my $index = 0;
    foreach (@articles) {
        my ($list, $article) = split(/\//, $_);

        my $file = "$SMARTLIST_PATH/$list/publish/$article";

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
        my $subject = getDecodedSubject($MAIL_HEADER->get('subject'));
        chomp($subject);
        $subject = encode_entities($subject, '<>&"');

        %fields = getListFields($list);
        $index++;
        $table .= <<EOF
        <tr>
                <td valign="top">$index.</td>
                <td align="left" style="text-align: left;">
                <a href="viewer.cgi?sid=$sid&amp;list=$list&amp;article=$article" title="[$list] $fields{'DESC'}">$subject</a>
                </td>
        </tr>
EOF
;
        if ($index > 9) {
            last;
        }
    }

    if ($table ne '') {
        $result .= <<EOF
<table>
$table
</table>
EOF
    }

    $result .= <<EOF
</div>
EOF
;
    return $result;
}

sub getWidgetClientInfo
{
    my $remote_addr = defined($ENV{'REMOTE_ADDR'}) ?
                      $ENV{'REMOTE_ADDR'} : '無';
    my $remote_host = defined($ENV{'REMOTE_HOST'}) ?
                      $ENV{'REMOTE_HOST'} : '無';

    $remote_host = gethostbyaddr(inet_aton($remote_addr), AF_INET) || '無'
        if (($remote_addr ne '無') && ($remote_host eq '無'));

    my $user_agent  = defined($ENV{'HTTP_USER_AGENT'}) ?
                      $ENV{'HTTP_USER_AGENT'} : '無';
    ($user_agent) = split(/\s/, $user_agent);
    $user_agent = defined($user_agent) ? $user_agent : '無';
    my $result .= <<EOF
<!-- auto-generated -->
<div class="widget">
<h4>訪客資訊</h4>
來源位址：$remote_addr ($remote_host)<br />
瀏覽器資訊：$user_agent
</div>
<!-- auto-generated -->
EOF
;
    return $result;
}

sub getWidgetSession
{
    my ($l, $sid, $u, $h) = ourSession::sessionCheck();

    my $remote_addr = defined($ENV{'REMOTE_ADDR'}) ?
                      $ENV{'REMOTE_ADDR'} : '無';
    my $remote_host = defined($ENV{'REMOTE_HOST'}) ?
                      $ENV{'REMOTE_HOST'} : '無';

    $remote_host = gethostbyaddr(inet_aton($remote_addr), AF_INET) || '無'
        if (($remote_addr ne '無') && ($remote_host eq '無'));

    my $user_agent  = defined($ENV{'HTTP_USER_AGENT'}) ?
                      $ENV{'HTTP_USER_AGENT'} : '無';
    ($user_agent) = split(/\s/, $user_agent);
    $user_agent = defined($user_agent) ? $user_agent : '無';

    my $result .= <<EOF
<!-- auto-generated -->
<div class="widget">
<h4>管理者資訊</h4>
<div align="left">
電子報：$l<br />
管理者：$u\@$h<br />
來源位址：$remote_addr ($remote_host)<br />
瀏覽器資訊：$user_agent
</div>
<a href="logout.cgi?sid=$sid">[ 登出 ]</a>
</div>
<!-- auto-generated -->
EOF
;
    return $result;
}

sub getAdminMenu
{
    my $sid = shift;
    my $menu = <<EOF
<!-- auto-generated -->
        <li><a href="index.cgi?sid=$sid">電子報首頁</a></li>
        <li><a href="archives.cgi?sid=$sid">電子報全覽</a></li>
        <li><a href="reader.cgi?sid=$sid">訂閱戶專區</a></li>
        <li><a href="admin.cgi?sid=$sid">管理者專區</a></li>
        <li><a href="stat.cgi?sid=$sid">統計資料</a></li>
	<li><a href="help.cgi?sid=$sid">操作說明</a></li>
        <li><a href="contact.cgi?sid=$sid">連絡我們</a></li>
<!-- auto-generated -->
EOF
;
    return $menu;
}

sub getWidgetCalendar
{
    my ($cgi, $month, $year) = @_;
    $month = defined($month) ? $month : (localtime(time()))[4] + 1;
    $year  = defined($year)  ? $year  : (localtime(time()))[5] + 1900;
    $cgi   = defined($cgi)   ? $cgi   : 'index.cgi';

    $month =~ s/[^0-9]//g;
    $year  =~ s/[^0-9]//g;

    # lyshie_20080620: show Taiwanese
    my $cal = "/usr/bin/cal";
    my @tmp = `$cal $month $year`;

    chomp($tmp[0]);
    $tmp[0] =~ s/^\s+//g;
    $tmp[0] =~ s/\s+$//g;

    my ($prev_m, $prev_y, $next_m, $next_y) =
       ($month - 1, $year, $month + 1, $year);

    if (($month eq '') || ($year eq '')) {
       $prev_m = (localtime(time()))[4];
       $prev_y = (localtime(time()))[5] + 1900;
       $next_m = (localtime(time()))[4] + 2;
       $next_y = (localtime(time()))[5] + 1900;
    }

    if ($prev_m == 0) {
        $prev_m = 12;
        $prev_y--;
    }

    if ($next_m == 13) {
        $next_m = 1;
        $next_y++;
    }

    my $bar = '<tr class="listheader">';
    # lyshie_20080530: Solaris 'cal' support
    $tmp[1] =~ s/^\s+//g;
    #
    foreach (split(/\s+/, $tmp[1])) {
        $bar .= "<td>$_</td>";
    }
    $bar .= '</tr>';

    my $table = '';
    for (my $i = 2; $i < @tmp; $i++) {
        chomp($tmp[$i]);
        next if ($tmp[$i] eq '');
        $tmp[$i] .= ' ';
        $table .= '<tr class="list">';
        my $c = 0;
        while ($tmp[$i] =~ m/([\s\d][\s\d]\s)/) {
            $c++;
            my $t = $1;
            $t =~ s/\s//g;
            if ($t eq '') {
                $tmp[$i] =~ s/([\s\d][\s\d]\s)/<td>&nbsp;<\/td>/;
                next;
            }
            if (($year == (localtime(time()))[5] + 1900) && 
                ($month == (localtime(time()))[4] + 1) &&
                ($t == (localtime(time()))[3])) {
                $tmp[$i] =~ s/([\s\d][\s\d]\s)/<td style="background\-color: #cccc00;"><a href="$cgi?sid=$sid&amp;d=$t&amp;m=$month&amp;y=$year">$t<\/a><\/td>/;
            }
            else {
                $tmp[$i] =~ s/([\s\d][\s\d]\s)/<td><a href="$cgi?sid=$sid&amp;d=$t&amp;m=$month&amp;y=$year">$t<\/a><\/td>/;
            }
        }
        if ($c < 7) {
            for (my $j = $c; $j < 7; $j++) {
                $tmp[$i] .= '<td>&nbsp;</td>';
            }
        }
        $table .= "$tmp[$i]</tr>";
    }

    my $result = <<EOF
<!-- auto-generated -->
<div class="widget">
<h4>月曆</h4>
<br />
<table class="light" align="center">
<tr class="listheader">
	<td><a href="$cgi?sid=$sid&amp;m=$prev_m&amp;y=$prev_y">&lt;&lt;</a></td>
	<td colspan="5"><a href="$cgi?sid=$sid&amp;m=$month&amp;y=$year">$tmp[0]</a></td>
	<td><a href="$cgi?sid=$sid&amp;m=$next_m&amp;y=$next_y">&gt;&gt;</a></td>
</tr>
	$bar
	$table
</table>
</div>
<!-- auto-generated -->
EOF
;
    return $result;
}

sub getWidgetValidation
{
    my $result = <<EOF
<!-- auto-generated -->
<div class="widget">
<p>
<a href="http://validator.w3.org/check?uri=referer">
<img src="http://www.w3.org/Icons/valid-xhtml10" border="0"
alt="Valid XHTML 1.0 Transitional" height="31" width="88" />
</a>
</p>
</div>
<!-- auto-generated -->
EOF
;

    return $result;
}

sub getWidgetContainer
{
    my @widgets = @_;
    my $result = <<EOF
<!-- widget container -->
EOF
;
    foreach (@widgets) {
        $result .= $_;
    }

    $result .= <<EOF
<!-- widget container -->
EOF
;

    return $result;
}

sub getWidgetCWB
{
    my %zones = ('0taipei'    => '台北',
                 '1hsinchu'   => '新竹',
                 '2taichung'  => '台中',
                 '3tainan'    => '台南',
                 '4kaohsiung' => '高雄',
                );

    my $weather = '';
    my $weather2 = '';

    foreach my $zone (sort(keys(%zones))) {
        my $city = $zone;
        $city =~ s/^\d//g;
        my $temperature = '&nbsp;';
        my $precipitation = '&nbsp;';
        my $comfort = '&nbsp;';
        my $temperature2 = '&nbsp;';
        my $precipitation2 = '&nbsp;';
        my $comfort2 = '&nbsp;';


        open(FH, "$Bin/cwb/$city.txt");
        while (<FH>) {
            if ($_ =~ m/W002.txt/) {
                $_ =~ m/(\d+)%/;
                $precipitation = $1;
                $_ =~ m/(\d+)\s+\-\s+(\d+)/;
                $temperature = "$1~$2";
            }
            if ($_ =~ m/W020.txt/) {
                ($comfort, $comfort, $comfort2) = split(/\s+/, $_);
            }
            if ($_ =~ m/W042.txt/) {
                $_ =~ m/(\d+)%/;
                $precipitation2 = $1;
                $_ =~ m/(\d+)\s+\-\s+(\d+)/;
                $temperature2 = "$1~$2";
            }
        }
        close(FH);

        $weather .= <<EOF
<tr class="list">
<td>$zones{$zone}</td><td>$temperature</td><td>$precipitation%</td><td>$comfort</td>
</tr>
EOF
;
        $weather2 .= <<EOF
<tr class="list">
<td>$zones{$zone}</td><td>$temperature2</td><td>$precipitation2%</td><td>$comfort2</td>
</tr>
EOF
;
    }

    my $result = <<EOF
<!-- auto-generated -->
<div class="widget">
<h4>今日白天氣象</h4>
<br />
<table class="light" align="center" width="100%">
<tr class="listheader">
<td>地區</td><td>氣溫</td><td>降雨</td><td>舒適</td>
</tr>
$weather
</table>
<br />
<h4>今晚明晨氣象</h4>
<br />
<table class="light" align="center" width="100%">
<tr class="listheader">
<td>地區</td><td>氣溫</td><td>降雨</td><td>舒適</td>
</tr>
$weather2
</table>
</div>
<!-- auto-generated -->
EOF
;

    return $result;
}

sub getWidgetNTHUNews
{
    my $nthu_urls = "$SMARTLIST_PATH/www/cgi-bin/utils/nthu_urls.txt";
   return "" unless (-f $nthu_urls);

    my $table = "";
    my $index = 0;

    open(FH, $nthu_urls);
    while (<FH>) {
        $index++;
        chomp($_);
        my ($title, $url) = split(/\t+/, $_);
        $title = encode_entities($title, '<>&"');
        $url   = encode_entities($url, '<>&"');
        $table .= <<EOF
    <tr>
        <td valign="top">$index.</td>
        <td align="left" style="text-align: left;">
        <a href="$url" title="$title" target="_blank">$title</a>
        </td>
    </tr>
EOF
;
    }
    close(FH);
    my $result = <<EOF
<!-- auto-generated -->
<div class="widget">
<h4><a href="http://www.nthu.edu.tw/" target="_blank">清大首頁新聞</a></h4>
<table>
$table
</table>
</div>
<!-- auto-generated -->
EOF
;
}
