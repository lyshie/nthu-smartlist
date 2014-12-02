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
BEGIN { $INC{'ListPager.pm'} ||= __FILE__ };

package ListPager;
use FindBin qw($Bin);
use lib "$Bin";
use ListUtils;
use CGI qw(:standard);
use POSIX;

our @ISA = qw(Exporter);
our @EXPORT = qw(isNumber
                 isValidIndex
                 isValidLength
                 isValidBound
                 getLowBound
                 getUpBound
                 getMaxIndex
                );

sub isNumber
{
    my $num = shift;
    if ($num =~ m/^[1-9]+[0-9]*$/) {
        return 1;
    }
    else {
        return 0;
    }
}

sub isValidIndex
{
    my $num = shift;
    # less than 0 or equal 0
    if ($num <= 0) {
        return 0;
    }

    if ($num > 100) {
        return 0;
    }

    return 1;
}

sub isValidLength
{
    my $num = shift;
    # less than 0 or equal 0
    if ($num <= 0) {
        return 0;
    }

    if ($num > 100) {
        return 0;
    }

    return 1;
}

sub isValidBound
{
    my ($index, $length, $total) = @_;

    my $upper = ceil($total / $length);
    if ($index > $upper) {
        return 0;
    }

    return 1;
}

sub getLowBound
{
    my ($index, $length) = @_;
    return ($index - 1) * $length;
}

sub getUpBound
{
    my ($index, $length) = @_;
    return $index * $length - 1;
}

sub getMaxIndex
{
    my ($length, $total) = @_;
    return ceil($total / $length);
}
