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
BEGIN { $INC{'ListSearch.pm'} ||= __FILE__ };

package ListSearch;
use MIME::Words qw(:all);
use Mail::Internet;
use Email::Valid;
use FindBin qw($Bin);
use lib "$Bin";
use ListUtils;
use Text::Iconv;

our @ISA = qw(Exporter);
our @EXPORT = qw(searchSubject
                 searchContent
                 searchFrom
                 searchTo
                );

sub searchSubject
{
    my ($keyword, $listname, $match_ref) = @_;
    $keyword = defined($keyword) ? $keyword : '';
    $listname = defined($listname) ? $listname : '';

    return if ($keyword eq '');

    my @match = ();

    my @files = ();
    my $path = '';

    if (($listname eq '') && defined($match_ref) && (@$match_ref == 0)) {
        my @lists = getListNames();
        # for convinence, it'd never be stack overflow
        foreach (@lists) {
            my %fields = getListFields($_);
            if (($fields{'VISI'} eq '1') && ($fields{'PUBL'} eq '1')) {
                push(@match, searchSubject($keyword, $_, $match_ref));
            }
        }
    }
    else {
        if (defined($match_ref) && (@$match_ref > 0)) {
            foreach my $m (@$match_ref) {
                my ($l, $f) = split(/\//, $m);
                $path = "$SMARTLIST_PATH/$l/publish";

                my $subject =
                        lc(getDecodedSubjectFromFile("$path/$f"));
                my $index = index($subject, lc($keyword));
                push(@match, "$l/$f") if ($index != -1);
            }
        }
        else {
            $path = "$SMARTLIST_PATH/$listname/publish";
            if (-d $path) {
                opendir(DH, $path);
                @files = grep { -f "$path/$_" } readdir(DH);
                closedir(DH);
            }
        
            foreach my $file (@files) {
                my $subject =
                        lc(getDecodedSubjectFromFile("$path/$file"));
                my $index =index($subject, lc($keyword));
                push(@match, "$listname/$file") if ($index != -1);
            }
        }
    }
    return @match;
}
