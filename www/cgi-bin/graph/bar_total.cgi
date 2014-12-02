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
umask(0000);
use FindBin qw($Bin);
use lib "$Bin/..";
use ListUtils;
use ListTemplate;
use GD::Graph::bars;
use GD::Graph::hbars;
use GD::Graph::Data;

my $FILE_BAR   = "$SMARTLIST_PATH/www/htdocs/images/graph/bar_total.png";

my %FONT_LARGE = ( 'name' => "$Bin/bsmi00lp.ttf",
                   'size' => 12,
                 );

my %FONT_MEDIUM = ( 'name' => "$Bin/bsmi00lp.ttf",
                    'size' => 10,
                  );

my %FONT_TINY   = ( 'name' => "$Bin/bsmi00lp.ttf",
                    'size' => 9,
                  );

my $GRAPH;
my $GRAPH_DATA = ();

sub getListData
{
    my @listnames = sort {(getApprovedArticles($b) || 0) <=>
                          (getApprovedArticles($a) || 0)}
                         (getListNames());
    my @names    = ();
    my @publish  = ();
    my @approved = ();

    foreach (@listnames) {
        next if ($_ eq 'digest');
        my %fields = getListFields($_);
        next unless $fields{'VISI'};
        my $p = getPublishArticles($_);
        my $a = getApprovedArticles($_);
        push(@names, "[$_] $fields{'DESC'}");
        push(@publish, $p);
        push(@approved, $a);
    }

    $GRAPH_DATA = GD::Graph::Data->new([\@names,
                                        \@approved,
                                        \@publish,
                  ]) or die GD::Graph::Data->error;
}

sub setFont
{
    $GRAPH->set_title_font($FONT_LARGE{'name'}, $FONT_LARGE{'size'});
    $GRAPH->set_legend_font($FONT_MEDIUM{'name'}, $FONT_MEDIUM{'size'});
    $GRAPH->set_values_font($FONT_TINY{'name'}, $FONT_TINY{'size'});

    $GRAPH->set_x_axis_font($FONT_TINY{'name'}, $FONT_TINY{'size'});
    $GRAPH->set_x_label_font($FONT_TINY{'name'}, $FONT_TINY{'size'});

    $GRAPH->set_y_axis_font($FONT_TINY{'name'}, $FONT_TINY{'size'});
    $GRAPH->set_y_label_font($FONT_TINY{'name'}, $FONT_TINY{'size'});
}

sub main
{
    getListData();
    my $height = scalar(getListNames()) * 20 + 100;
    $GRAPH = GD::Graph::hbars->new(680, $height);

    my $x_label = reverse Encode::decode('utf-8', '電子報名稱');

    $GRAPH->set(
        x_label         => $x_label,
        y_label         => '電子報數量',
        title           => '電子報發行統計',
        y_plot_values   => 1,
        x_plot_values   => 1,
        # shadows
        shadow_depth    => 1,
        shadowclr       => 'dred',
        transparent     => 100,
        show_values     => 1,
        values_space    => 4,
    )
    or warn $GRAPH->error;

    $GRAPH->set_legend(('已發行電子報', '公開發行電子報'));

    setFont();

    #umask(0000);
    open(OUT, ">$FILE_BAR") or
        die "Cannot open $FILE_BAR for write: $!";
    binmode OUT;
    print OUT $GRAPH->plot($GRAPH_DATA)->png();
    close OUT;
}

main();
