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

my $VALIDATE_PATH = "/tmp/validate";
my $PERIOD_MAX    = 60 * 20;

sub main
{
    my @files = ();
    opendir(DH, "$VALIDATE_PATH");
    @files = grep { -f "$VALIDATE_PATH/$_" && m/\d{6}/ } readdir(DH);
    closedir(DH);

    my $now = time();
    foreach (@files) {
        my $file = "$VALIDATE_PATH/$_";
        my $period = $now - (stat("$file"))[9];
        print "deleted $file = $period > $PERIOD_MAX\n" if ($period > $PERIOD_MAX);
        unlink($file);
    }
}

main();
