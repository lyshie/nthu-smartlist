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
use lib "$Bin";
use ListUtils;

sub main {
    my @lists = getListNames();

    foreach my $list (@lists) {
        my $dist_file = "$SMARTLIST_PATH/$list/dist";
        next if (!-f $dist_file);

        open(FH, $dist_file);
        my @items = <FH>;
        close(FH);

        foreach my $item (@items) {
            next if ($item =~ m/^\(Only addresses/);

            if ($item =~ m/[A-Z]/) {
                chomp($item);
                printf("[%s] %s\n", $list, $item);
            }
        }
    }
}

main;
