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
BEGIN { $INC{'ListLog.pm'} ||= __FILE__ };

package ListLog;
use FindBin qw($Bin);
use lib "$Bin";
use ListUtils;

our @ISA = qw(Exporter);
our @EXPORT = qw(logToList
                 logParse
                );

# lyshie_20080827: an easy interface to log events
sub logToList
{
    my ($listname, $fmt, @msgs) = @_;
    return unless getListFields($listname);
    open(FH, ">>$SMARTLIST_PATH/$listname/log.smartlist");
    printf FH "%s $fmt\n", time(), @msgs;
    close(FH);
}

sub logParse
{
    my $line = shift;
    my ($time, $program, $token, $msg) = ('', '', '');

    $line =~ m/^(\d+)\s\[(.*?)\]\s(.*?)\s\((.*)\)$/;
    ($time, $program, $token, $msg) = ($1, $2, $3, $4);

    return ($time, $program, $token, $msg);
}
