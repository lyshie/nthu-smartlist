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

my $DIST     = "$Bin/dist.txt";
my $UNNEEDED = "$Bin/unneeded.txt";

my %LISTS = ();

sub checkFiles
{
    die("Can't open $DIST")     unless (-f $DIST);
    die("Can't open $UNNEEDED") unless (-f $UNNEEDED);
}

sub loadFiles
{
    open(FH, "$DIST");
    while (<FH>) {
        chomp($_);
        s/^\s+//g;
        s/\s+^//g;
        my ($line, $word, $byte, $name) = split(/\s+/, $_);
        $name =~ s/.+\/(.+)\/dist/$1/;
        $LISTS{$name}{'dist'} = $line - 1;
    }
    close(FH);

    open(FH, "$UNNEEDED");
    while (<FH>) {
        chomp($_);
        s/^\s+//g;
        s/\s+^//g;
        my ($line, $word, $byte, $name) = split(/\s+/, $_);
        $name =~ s/.+\/(.+)\/unneeded/$1/;
        $LISTS{$name}{'unneeded'} = $line;
    }
    close(FH);
}

sub show
{
    my @lists = ();
    @lists = getListNames();
    @lists = sort(@lists);

    printf("%-20s | %10s | %10s | %8s | %8s | %8s\n",
           'Name',
           'Dist',
           'Unneeded',
           'Approved',
           'Publish',
           'Moderate'
          );

    print "================================================================================\n";

    my $total_dist     = 0;
    my $total_unneeded = 0; 
    my $total_approved = 0;
    my $total_publish  = 0;
    my $total_moderate = 0;

    foreach (@lists) {
        #next if ($_ eq 'digest');
        if (defined($LISTS{$_})) {
            my $approved = scalar(getApprovedArticles($_)) || 0;
            my $publish  = scalar(getPublishArticles($_))  || 0;
            my $moderate = scalar(getModerateArticles($_)) || 0;

            printf("%-20s | %10d | %10d | %8d | %8d | %8d\n",
                   $_,
                   $LISTS{$_}{'dist'} || 0,
                   $LISTS{$_}{'unneeded'} || 0,
                   $approved,
                   $publish,
                   $moderate
                  );
            $total_dist     += $LISTS{$_}{'dist'}     || 0;
            $total_unneeded += $LISTS{$_}{'unneeded'} || 0;
            $total_approved += $approved;
            $total_publish  += $publish;
            $total_moderate += $moderate;
        }
    }

    print "================================================================================\n";
    printf("%-20s | %10d | %10d | %8d | %8d | %8d\n",
           'Total',
           $total_dist,
           $total_unneeded,
           $total_approved,
           $total_publish,
           $total_moderate
          );
}

sub main
{
    checkFiles();
    loadFiles();
    show();
}

main();
