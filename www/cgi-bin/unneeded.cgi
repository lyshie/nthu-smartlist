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
use ourSession;
use ListUtils;
use HTTP::BrowserDetect;
#

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

sub attachDist
{
    my $filename = "$listname" . "_unneeded_" . time() . ".txt";
    print <<EOF
Content-Disposition: attachment; filename=$filename

EOF
;
    my @dists = ();
    open(FH, "$SMARTLIST_PATH/$listname/unneeded");
    @dists = <FH>;
    close(FH);

    my $browser = new HTTP::BrowserDetect($ENV{'HTTP_USER_AGENT'});

    my $eol = "\n";
    if ($browser->windows()) {
        $eol = "\r\n";
    }

    foreach my $line (@dists) {
        chomp($line);
        print "$line$eol";
    }
}

sub main
{
    attachDist();
}

main();
