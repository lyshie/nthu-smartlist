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
use Email::Valid;
use File::Basename;
use File::Copy;
#

sub fix_email {
    my ($list) = @_;

    my $dist_file = "$SMARTLIST_PATH/$list/dist";
    my $old_dist_file = "$SMARTLIST_PATH/$list/dist.old";

    if (!-f $dist_file) {
        print "\t[ERROR] can not find dist file.\n";
        return;
    }

    copy($dist_file, $old_dist_file);

    open(FH, $old_dist_file);

    open(WFH, ">$dist_file");

    print WFH "(Only addresses below this line can be automatically removed)\n";

    while (<FH>) {
        my $email = $_;
        chomp($email);
        next if ($email =~ m/^#/);
        next if ($email eq '(Only addresses below this line can be automatically removed)');
        unless (Email::Valid->address($email)) {
            print STDERR "\t[WARN] $email\n";
        }
        else {
            print WFH $email, "\n";
        }
    }

    close(WFH);

    close(FH);
}

sub main {
    my @lists = getListNames();

    foreach my $list (sort @lists) {
        printf("==== %s ====\n", $list);
        fix_email($list);
    }
}

main;
