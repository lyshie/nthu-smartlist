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

use FindBin qw($Bin);
use LWP::UserAgent;

use constant C_TIME => 10;

my $NEWS_FILE = "$Bin/nthu_news.txt";
my $URLS_FILE = "$Bin/nthu_urls.txt";
my $URL       = "http://www.nthu.edu.tw/";
my $B_LATEST  = '最新消息';
my $B_NTHU    = '<!-- start of NTHU News-->';
my $E_NTHU    = '<!-- end of NTHU News -->';
my $MAX_AGE   = 60 * 10;

sub loadHTML
{
    my $html = "";

    if (-f $NEWS_FILE) {
        my $ctime = (stat($NEWS_FILE))[C_TIME];
        if (time() -  $ctime > $MAX_AGE) {
            unlink($NEWS_FILE);
        }
    }

    if (-f $NEWS_FILE) {
        open(FH, "$NEWS_FILE");
        while (<FH>) {
            $html .= $_;
        }
        close(FH);
    }
    else {
        my $ua = LWP::UserAgent->new();
        $ua->timeout(10);
        my $resp = $ua->get($URL);
        if ($resp->is_success()) {
            $html = $resp->content();
            open(FH, ">$NEWS_FILE");
            print FH $html;
            close(FH);
        }
    }

    return $html;
}

sub trim
{
    my $s = shift;
    $s =~ s/^\s+//g;
    $s =~ s/\s+$//g;

    return $s;
}

sub restoreURL
{
    my $url = shift;
    $url = trim($url);
   
    $url =~ s/^\///g;

    if ($url !~ m/\Qhttp:\/\/\E/) {
        return $URL . $url;
    }
    else {
        return $url;
    }
}

sub main
{
    my $nthu_news = "";
    my $latest_news = "";
    my $html = loadHTML();

    $html =~ m/\Q$B_LATEST\E(.*)\Q$B_NTHU\E/s;
    $latest_news = $1 if ($1);

    $html =~ m/\Q$B_NTHU\E(.*)\Q$E_NTHU\E/s;
    $nthu_news = $1 if ($1);

    open(FH, ">$URLS_FILE");

    while ($latest_news =~
               s/index_news_12.*?<a[^<>]*href="(.*?)"[^<>]*>(.*?)<\/a>//s)
    {
        if ($1 && $2 && $2 !~ /&lt;more&gt;/) {
            print FH trim($2), "\t";
            print FH restoreURL($1), "\n";
        }
    }

    while ($nthu_news =~
               s/<a[^<>]*href="(.*?)"[^<>]*>(.*?)<\/a>//s)
    {
        if ($1 && $2 && $2 !~ /&lt;more&gt;/) {
            print FH trim($2), "\t" if ($2);
            print FH restoreURL($1), "\n" if ($1);
        }
    }

    close(FH);
}

main();
