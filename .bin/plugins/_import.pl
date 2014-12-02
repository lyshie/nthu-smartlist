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
#
# Shie, Li-Yi <lyshie@mx.nthu.edu.tw>
# 1. Import old configure file
#
use FindBin qw($Bin);
#
use lib "$Bin";
use ListUtils;
#

my $CREATELIST = "$SMARTLIST_PATH/.bin/createlist";
my $MODERATE   = "$SMARTLIST_PATH/.bin/plugins/moderate.pl";
my $CONFIRM    = "$SMARTLIST_PATH/.bin/plugins/confirm.pl";

sub main
{
    foreach my $line (<STDIN>) {
        chomp($line);
        if ($line !~ m/^\#/) {
            my @tokens = split(/:/, $line);
            my %fields = ();
            $fields{'VISI'} = ($tokens[0] eq '0') ? '1' : '0';
            $fields{'NAME'} = $tokens[1];
            $fields{'DESC'} = $tokens[2];
            $fields{'MAIN'} = $tokens[4];
            $fields{'ORGA'} = $tokens[3];
            $fields{'MAIL'} = 'lyshie@r309-2.cc.nthu.edu.tw';
            $fields{'PHON'} = $tokens[6];
            $fields{'PUBL'} = $tokens[7];
#            system($CREATELIST, $fields{'NAME'}, 'lyshie@r309-2.cc.nthu.edu.tw');
            
#            open(FH, ">>$SMARTLIST_PATH/aliases");
#            my $lines = <<EOF
#$fields{'NAME'}: "|exec $MODERATE $fields{'NAME'}"
#$fields{'NAME'}-request: "|exec $CONFIRM $fields{'NAME'}-request"
#EOF
#;
#            print FH $lines;
#            close(FH);

            my $line = '';
            foreach (@SORTED_FIELDS) {
                $line .= "$fields{$_}:";
            }
            $line =~ s/:$/\n/;

            open(FH, ">>$SMARTLIST_PASSWD");
            print FH $line;
            close(FH);
#            setListFields(\%fields);
        }
    }
}

main();
