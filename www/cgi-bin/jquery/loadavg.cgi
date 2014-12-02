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
use CGI qw(:standard);
use XML::Writer;

my $LOADAVG_FILE = "/proc/loadavg";

my ($avg_1, $avg_5, $avg_15) = ('', '', '');

sub main
{
    open(FH, $LOADAVG_FILE);
    my $line = <FH>;
    chomp($line);
    close(FH);

    ($avg_1, $avg_5, $avg_15) = split(/\s+/, $line);

    my $xml = '';
    my $writer = new XML::Writer(OUTPUT => \$xml,
                                 ENCODING => 'utf-8',
                                 DATA_MODE => 1,
                                 DATA_INDENT => 4);
    $writer->xmlDecl("UTF-8");
    $writer->startTag('loadavg');

    $writer->dataElement('avg1' => $avg_1);
    $writer->dataElement('avg5' => $avg_5);
    $writer->dataElement('avg15' => $avg_15);

    $writer->endTag();
    $writer->end();

    print header(-charset => 'utf-8', -type => 'text/xml');
    print $xml;
}

main();
