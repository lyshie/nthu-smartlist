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
use HTML::TreeBuilder;
use Algorithm::Diff qw(LCS);
use Encode qw(encode decode from_to);
use Digest::MD5 qw(md5_hex);

my %FILES = (
    adm      => 'content_adm_gary.php',
    research => 'content_research_gary.php',
    edu      => 'content_education_gary.php',
);

sub load_file {
    my ($filename) = @_;

    my $result = '';

    local $/ = undef;
    open( FH, $filename );
    $result = <FH>;
    close(FH);

    return decode( "utf-8", $result );
}

sub get_units {
    my ($unit) = @_;

    my @result = (
        decode( "utf-8", "研究生聯合會;研究生聯合會;其他" ),
        decode( "utf-8", "電子報系統;電子報系統;SYSTEM" ),
    );

    my $tree = HTML::TreeBuilder->new();

    $tree->parse( load_file("$Bin/$FILES{$unit}") );

    my @links = $tree->find_by_attribute( "class", "thin12_aboutnthu_black" );

    foreach (@links) {
        my $parent = '';

        my @a = $_->look_down( "_tag", "a" );

        if (@a) {
            ($parent) = ( $a[0]->content_list() );
        }

        foreach (@a) {
            foreach my $item ( $_->content_list() ) {
                push( @result, "$item;$parent" );
            }
        }
    }
    $tree->delete();

    return @result;
}

sub unit_match {
    my ( $keyword, @units ) = @_;

    $keyword = decode( "utf-8", $keyword );

    my @ks = split( //, $keyword );

    my $max       = -1;
    my $candidate = '';

    foreach my $unit (@units) {
        my $u = $unit;
        $u =~ s/;.*//g;
        my @us = split( //, $u );
        my @lcs = LCS( \@ks, \@us );
        if ( scalar(@lcs) > $max ) {
            $max       = scalar(@lcs);
            $candidate = $unit;
        }
    }

    return encode( "utf-8", $candidate );
}

sub load_units {
    my @results = ();
    foreach my $u ( get_units('adm') )
    {
        $u =~ s/（/(/g;
        $u =~ s/）/)/g;
        $u =~ s/\s//g;
        push( @results, $u . decode( "utf-8", ";行政單位" ) );
    }

    foreach my $u ( get_units('edu') )
    {
        $u =~ s/（/(/g;
        $u =~ s/）/)/g;
        $u =~ s/\s//g;
        push( @results, $u . decode( "utf-8", ";教學單位" ) );
    }

    foreach my $u ( get_units('research') )
    {
        $u =~ s/（/(/g;
        $u =~ s/）/)/g;
        $u =~ s/\s//g;
        push( @results, $u . decode( "utf-8", ";研究中心" ) );
    }

    return @results;
}

sub main {
    my @UNITS = load_units();

    my @LISTS = ();

    while (<ARGV>) {
        my $line = $_;
        chomp($line);
        my ( $listname, $description, undef, $unit ) = split( /[:]/, $line );
        my ( $self, $parent, $type ) = split( /;/, unit_match( $unit, @UNITS ) );
        my %hash = (
            'name'   => $listname,
            'desc'   => $description,
            'parent' => $parent,
            'unit'   => $self,
            'type'   => $type,
            'digest' => md5_hex($parent),
        );
        push( @LISTS, \%hash );
    }

    foreach my $u (
        sort {
                 $a->{'parent'} cmp $b->{'parent'}
              || $a->{'name'} cmp $b->{'name'}
        } @LISTS
      )
    {
        printf( "%s:%s:%s:%s:%s\n",
            $u->{'name'}, $u->{'parent'}, $u->{'unit'}, $u->{'type'}, $u->{'digest'});
    }
}

main;
