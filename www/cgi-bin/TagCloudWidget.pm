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
BEGIN { $INC{'TagCloudWidget.pm'} ||= __FILE__ };

package TagCloudWidget;

use CGI qw(:standard);
use HTML::Entities;
use FindBin qw($Bin);
use List::Util qw(shuffle);

our @ISA = qw(Exporter);
our @EXPORT = qw(getWidgetTagCloud
                );

my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my %TAG_CLOUD = ();

sub getWidgetTagCloud
{
    open(FH, "$Bin/phrases/freq");
    while (<FH>) {
        my $line = $_;
        chomp($line);
        my ($tag, $times) = split ( /[=\s]+/, $line);
        $TAG_CLOUD{$tag} = int($times);
    }
    close(FH);

    my @tags = sort {$TAG_CLOUD{$b} <=> $TAG_CLOUD{$a}}
                    keys(%TAG_CLOUD);

    my @clouds = ();
    for (my $i = 0; $i < 30; $i++) {
        my $tmp = shift(@tags);
        last unless defined($tmp);
        push(@clouds, $tmp);
    }

    my $html = '';
    my $size;
    my $fontsize;
    my $color;
    my $url;
    my $tag; 
    my $max = $TAG_CLOUD{$clouds[0]};

    @clouds = shuffle(@clouds);
    foreach (@clouds) {
        $size = $TAG_CLOUD{$_};
        $size = int($size * 12 / $max + 8);
        $fontsize = $size . "pt";
        $url = CGI::escape($_);
        $tag = encode_entities($_, '<>&"');
        $color = sprintf("rgb(%d,%d,%d)", int(rand(225)),
                                          int(rand(225)),
                                          int(rand(225)));
        $html .= <<EOF
<a href="search.cgi?sid=$sid&amp;keyword=$url" style="font-size: $fontsize; color: $color;">$tag</a>&nbsp;
EOF
;
    }

    my $result = <<EOF
<!-- auto-generated -->
<div class="widget">
<h4>Tag Cloud</h4>
<br />
$html
</div>
<!-- auto-generated -->
EOF
;
    return $result;
}

1;
