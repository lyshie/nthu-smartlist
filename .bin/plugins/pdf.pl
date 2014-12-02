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
use ListUtils;
use LWP::UserAgent;
#
my $URL = "http://op7.oz.nthu.edu.tw/cgi-bin/wkhtmltopdf/htmltopdf.cgi?list=%s&article=%s";
my $URL_PDF = "http://op7.oz.nthu.edu.tw/pdf/%s.%s.pdf";
my $PDF_PATH = "$SMARTLIST_PATH/www/htdocs/pdf";
my $WGET = "/usr/sfw/bin/wget";

my @lists = getListNames();
my @articles = ();

foreach my $list (@lists) {
    my %fields = getListFields($list);
    # lyshie_20080326: the list should !hidden and public
    next if ($fields{'VISI'} eq '0');
    next if ($fields{'PUBL'} eq '0');

    push(@articles, getPublishArticles($list));
}

my $ua = LWP::UserAgent->new;
$ua->timeout(10);

foreach (@articles) {
    my ($list, $article) = split(/\//, $_);
    my $file = "$PDF_PATH/$list.$article.pdf";
    next if (-f $file);
    my $url = sprintf($URL, $list, $article);
    my $response = $ua->get($url);
    if ($response->is_success) {
        if ($response->decoded_content =~ m/(exist|success)/) {
            $url = sprintf($URL_PDF, $list, $article);
            `$WGET -O "$file" "$url"`;
        }
    }
}
