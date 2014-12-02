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
use DB_File;
use Fcntl;
#

my $VIEWER_DB = "$Bin/viewer.db";
my %DB = ();
my $DB_REF;

sub createDB
{
    tie(%DB, 'DB_File', $VIEWER_DB, O_CREAT|O_RDWR, 0777) ||
        die ("Cannot create or open $VIEWER_DB");
}

sub openDB
{
    $DB_REF = tie(%DB, 'DB_File', $VIEWER_DB) ||
        die ("Cannot open $VIEWER_DB");
}

sub readFromDB
{
    my $key = shift;
    my $record = $DB{$key} || 0;
    return $record;
}

sub writeToDB
{
    my $key   = shift;
    my $value = shift;
    $DB{$key} = $value;
}

sub closeDB
{
    undef($DB_REF);
    untie(%DB);
}

sub getRank
{
    # lyshie_20090922: using DB_File to store view counts
    if (!-f $VIEWER_DB) {
        die("Can't open $VIEWER_DB");
    }
    openDB();
    foreach (sort { ($DB{$b} <=> $DB{$a}) or ($a cmp $b) } keys(%DB)) {
        my ($list, $a) = split(/\./, $_);
        my $filename = "$SMARTLIST_PATH/$list/publish/$a";
        if (!-f $filename) {
            print "[ERROR] $filename\n";
            $DB_REF->del($_);
        }
        else {
            print "($DB{$_}) [$_] ", getDecodedSubjectFromFile($filename), "\n";
        }
    }
    closeDB();
}

sub main
{
    getRank();
}

main();
