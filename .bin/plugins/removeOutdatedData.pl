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
#
use constant C_TIME => 10;

my $GAP = 7 * 24 * 60 * 60;

sub getParams
{
    if (defined($ARGV[0])) {
        $ARGV[0] =~ s/[^\d]//g;
        if ($ARGV[0] ne '') {
            $GAP = $ARGV[0];
        }
    }
    #print $GAP;
}

sub main
{
    getParams();
    my $now= time();

    my @files = removeOutdatedData();
    foreach (@files) {
        my $ctime = (stat($_))[C_TIME];
        if ($now - $ctime > $GAP) {
            printf("unlink %s [%s]\n", $_, $now - $ctime);
            unlink($_);
        }
    }
}

main();
