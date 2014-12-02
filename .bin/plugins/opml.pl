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
use XML::OPML::SimpleGen;

my $URL         = "http://" . getListDomain();
my $RSS_PATH    = "$SMARTLIST_PATH/www/htdocs/rss";
my $RSS_BASEURL = "$URL/slist/rss";
my $OPML_FILE   = "$RSS_PATH/nthu.xml";

sub main
{
    my $opml = new XML::OPML::SimpleGen();
    $opml->head(title => '國立清華大學電子報');
    $opml->add_group(text => '國立清華大學電子報');

    my @lists = getListNames();

    foreach my $list (@lists) {
        my %fields = getListFields($list);
        next if ($fields{'VISI'} eq '0');
        next if ($fields{'PUBL'} eq '0');
        printf("[%s] [%s]\n", $fields{'NAME'}, $fields{'DESC'});
        $opml->insert_outline(text => $fields{'DESC'},
                              group => '電子報',
                              title => $fields{'DESC'},
                              xmlUrl => "$RSS_BASEURL/$fields{'NAME'}.xml",
                             );
    }

    my $content = $opml->as_string();
    $content =~ s/id=\"\d+\"\n\s+//g;
    $content =~ s/isOpen=\"true\"\n\s+//g;
    #$opml->save($OPML_FILE);
    #umask(0000);
    open(FH, ">$OPML_FILE");
    print FH $content;
    close(FH);
}

main();
