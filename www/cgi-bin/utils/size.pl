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
use CGI qw(:standard);
#

my %LISTS = ();

my @DU       = `/bin/du -s -k $SMARTLIST_PATH/*`;
my $DU_TOTAL = `/bin/du -s -k $SMARTLIST_PATH`;

sub show
{
    my @lists = ();
    @lists = getListNames();
    @lists = sort(@lists);

    chomp($DU_TOTAL);
    $DU_TOTAL =~ s/^(\d+).*/$1/g;

    foreach (@DU) {
        chomp($_);
        my ($size, $name) = split(/[\t\s]+/, $_);
        $name =~ s/.*\/(.+)/$1/;
        $LISTS{$name}{'size'} = $size;
    }

    printf("%-20s %-16s\n", 'Name', 'Size');
    printf("====================================================================\n");

    foreach (@lists) {
        #next if ($_ eq 'digest');
        if (defined($LISTS{$_})) {
            printf("%-20s %16d KB %10.2f MB %10.2f GB\n",
                   $_,
                   $LISTS{$_}{'size'},
                   $LISTS{$_}{'size'} / 1024,
                   $LISTS{$_}{'size'} / 1024 / 1024
                  );
        }
    }

    printf("====================================================================\n");
    printf("%-20s %16d KB %10.2f MB %10.2f GB\n",
           'Total',
           $DU_TOTAL,
           $DU_TOTAL / 1024,
           $DU_TOTAL / 1024 / 1024
          );
}

sub main
{
    show();
}

main();
