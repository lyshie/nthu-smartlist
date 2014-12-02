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
use File::Spec::Link;

use ListUtils;

my @lists = getListNames();

foreach my $list (@lists) {
    my $dir = "/usr/local/slist/$list/publish";
    opendir(DH, $dir);
    my @files = grep { -l "$dir/$_" } readdir(DH);
    closedir(DH);

    foreach (@files) {
        my $f = "$dir/$_";
        my $old_link = File::Spec::Link->full_resolve("$f");
        if ($old_link =~ m/\/home\/slist\/.*/) {
            unlink($f);
            my $new_link = "../approved/$_";
            print symlink($new_link, $f), "\n";
        }
    }
}
