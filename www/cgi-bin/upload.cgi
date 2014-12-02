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
use ListLog;
use ourSession;
use ListUtils;
use CGI qw(:standard);
use ListTemplate;
use Scalar::Util qw(openhandle);
use Email::Valid;
use File::Basename;
use Unix::Syslog qw(:macros :subs);
#
$CGI::POST_MAX   = 12 * 1024 * 1024; # max is 10~12 MB
my $TRANSFER_MAX = 10 * 1024 * 1024; # max is 10 MB

# the worest error
if (cgi_error()) {
     print header(-status=>cgi_error());
     exit(0);
}

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

my $action = '';
my $upload_dist_result = '';

sub getUploadDistContent
{
    my $dist = shift;
    my $result = <<EOF
<h2>上傳訂戶清單結果</h2>
<br />
<code>
$dist
</code>
<br />
<div align="center">
<a href="editdist.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub uploadDists
{
    my $cgi = new CGI;
    my $content = $cgi->upload('uploaded_file');

    if (!$content && cgi_error()) {
         print header(-status=>cgi_error());
         exit(0);
    }

    # over the length of content
    if ($ENV{'CONTENT_LENGTH'} > $TRANSFER_MAX) {
        $upload_dist_result = "您傳輸的資料量過大 ($ENV{'CONTENT_LENGTH'} bytes)，請先確認檔案容量小於 10MB 後再上傳！";
        return;
    }

    if (!openhandle($content)) {
        $upload_dist_result .= '上傳失敗！';
        return;
    }

    my @emails = ();
    foreach my $line (<$content>) {
        #chomp($line);
        $line =~ s/[\n\r]//g;  # lyshie_20080520: bugfix-compatible for CR/LF
        $line =~ s/\s//g;
        $line =~ s/[(<"].*?[">)]//g;
        next unless Email::Valid->address($line);
        push(@emails, $line);
        $upload_dist_result .= "加入 $line 至訂戶清單中；\n";
    }

    # lyshie_20080520: use `import` method to improve the performance
    for (my $i = 0; $i < scalar(@emails); $i++) {
        $emails[$i] =~ s/\s//g;
        $emails[$i] =~ s/[(<"].*?[">)]//g;
    }

    importDists($listname, \@emails);

    if ($upload_dist_result eq '') {
        $upload_dist_result = '沒有資料被加入！'
    }
    else {
        my @emails = getUnneeded($listname);
        removeDist($listname, \@emails);
        $upload_dist_result .= "移除 " . join("\n", @emails) . "，因為該使用者拒絕訂閱；\n";

        #foreach my $email (getUnneeded($listname)) {
        #   removeDist($listname, $email);
        #   $upload_dist_result .= "移除 $email\，因為該使用者拒絕訂閱；\n";
        #}
    }

    my @total = getDists($listname);
    syslog(LOG_INFO,
           "Upload dists. (sid=%s, total=%s, total_upload=%s)",
           $sid,
           scalar(@total) - 1,
           scalar(@emails),
          );

    logToList($listname,
              "[%s] UPLOAD DISTS (%s)",
              basename($0),
              $sid
             );
}

# lyshie_20080520: disable this function
sub updateFixedDists
{
#    my $fixed = '';
#    $fixed = param('dists');
#    $fixed = defined($fixed) ? $fixed : '';
#    my @dists = split(/[\n\r]/, $fixed);

#    my ($f, $a) = getDists($listname);
#    removeDist($listname, $_, 1) foreach (@$f);

#    foreach my $line (@dists) {
#        chomp($line);
#        next unless Email::Valid->address($line);
#        addDist($listname, $line, 1);
#        $upload_dist_result .= "更新 $line 至固定訂戶清單中；\n";
#    }

#    $upload_dist_result = '固定清單已清空！'
#        if ($upload_dist_result eq '');

#    syslog(LOG_INFO,
#           "(%s) Update fixed dists.",
#           $sid,
#          );
}

sub updateAutoDists
{
    my $auto = '';
    $auto = param('dists');
    $auto = defined($auto) ? $auto : '';
    my @dists = split(/[\n\r]/, $auto);

    my @emails = ();
    foreach my $line (@dists) {
        chomp($line);
        $line =~ s/\s//g;
        $line =~ s/[(<"].*?[">)]//g;
        next unless Email::Valid->address($line);
        #addDist($listname, $line);
        push(@emails, $line);
        $upload_dist_result .= "加入 $line 至訂戶清單中；\n";
    }

    # lyshie_20080520: assign `replace` mode
    # lyshie_20080901: assign `append` mode
    importDists($listname, \@emails);
    my @all_remove = ();

    if ($upload_dist_result eq '') {
        #$upload_dist_result = '自動清單已清空！'
        $upload_dist_result = '沒有資料被加入！'
    }
    else {
        my @emails = getUnneeded($listname);
        removeDist($listname, \@emails);
        $upload_dist_result .= "移除 " . join("\n", @emails) . "，因為該使用者拒絕訂閱；\n";

        #foreach my $email (getUnneeded($listname)) {
        #    my $is_removed = 0;
        #    ($is_removed, @all_remove) = removeDist($listname, $email);
        #    $upload_dist_result .= "移除 $email\，因為該使用者拒絕訂閱；\n";
        #}
    }

    my @total = getDists($listname);
    syslog(LOG_INFO,
           "Update auto dists. (sid=%s, total=%s, total_update=%s)",
           $sid,
           scalar(@total) - 1,
           scalar(@emails),
          );

    logToList($listname,
              "[%s] UPDATE AUTO DISTS (%s, %d)",
              basename($0),
              $sid,
              scalar(getDists($listname)) - 1,
             );
}

sub removeAutoDists
{
    my $auto = '';
    $auto = param('rdists');
    $auto = defined($auto) ? $auto : '';
    my @dists = split(/[\n\r]/, $auto);

    foreach my $line (@dists) {
        chomp($line);
        $line =~ s/\s//g;
        $line =~ s/[(<"].*?[">)]//g;
        # lyshie_20120406: bypassing email format check
        #next unless Email::Valid->address($line);
        my ($is_removed, @all) = removeDist($listname, $line);
        $upload_dist_result .= "$line 已不在訂戶清單中；\n";

        syslog(LOG_INFO,
               "Remove auto dists. (sid=%s, email=%s, total=%s)",
               $sid,
               $line,
               scalar(@all) - 1
              );

        logToList($listname,
                  "[%s] REMOVE AUTO DISTS (%s, %s, %d)",
                  basename($0),
                  $sid,
                  $line,
                  scalar(@all) - 1
                  );
    }

    if ($upload_dist_result eq '') {
        $upload_dist_result = '沒有資料被刪除！'
    }
}

sub getParams
{
    $action = param('action');
    $action = defined($action) ? lc($action) : '';
}

sub main
{
    openlog(basename($0), LOG_PID, LOG_LOCAL5);

    getParams();
    if ($action eq 'fixed') {
        updateFixedDists();
    }
    elsif ($action eq 'auto') {
        updateAutoDists();
    }
    elsif ($action eq 'remove') {
        removeAutoDists();
    }
    else {
        uploadDists();
    }

    print header(-charset=>'utf-8');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getAdminMenu($sid),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetSession(),
                           'WIDGET_3' => getNull(),
                           'CONTENT'  => getUploadDistContent($upload_dist_result),
                          }
                         );

    closelog();
}

main();
