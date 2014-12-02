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
use File::Copy;
#
######## BACKUP ALL LISTS FILES ########
my $BACKUP_PATH = "$SMARTLIST_PATH/%s/backup";
my $LIST_PATH   = "$SMARTLIST_PATH/%s";
my @FILES       = qw(dist unneeded accept reject);

my @lists = getListNames();

my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);

my $SUFFIX = sprintf("%04d%02d%02d", $year + 1900,
                                     $mon + 1,
                                     $mday);

foreach my $list (@lists) {
    print "$list\n";

    #my %fields = getListFields($list);

    my $backup_path = sprintf($BACKUP_PATH, $list);
    my $list_path   = sprintf($LIST_PATH, $list);

    mkdir($backup_path) if (!-d $backup_path);

    if (-d $backup_path) {
        foreach my $f (@FILES) {
            my $file = "$list_path/$f";
            if (-f $file) {
                copy($file, "$backup_path/$f.$SUFFIX");
            }
        }
    }
}

####### BACKUP SYSTEM FILES ########
my @SYS_FILES       = qw(passwd aliases);
my $path            = "$SMARTLIST_PATH/backup";

mkdir($path) if (!-d $path);
if (-d $path) {
    foreach my $f (@SYS_FILES) {
        my $file = "$SMARTLIST_PATH/$f";
        if (-f $file) {
            copy($file, "$path/$f.$SUFFIX");
        }
    }
}
