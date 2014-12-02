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
use utf8;
use Encode;
binmode(STDOUT, ":utf8");
#
umask(0000);
use FindBin qw($Bin);
use lib "$Bin";
use ListUtils;
use Mail::Internet;
#
my $DICT_PATH = "$Bin/phrases";
my %PHRASES = ();
my %KEYWORDS = ();

sub ngram_load
{
    # default is tri-gram
    my $size = shift || 3;

    for (my $i = 0; $i <= $size; $i++) {
        next if (!-f "$DICT_PATH/tab_$i");
        open(FH, "<:utf8", "$DICT_PATH/tab_$i");
        my $phrase;
        while (<FH>) {
            $phrase = $_;
            chomp($phrase);
            $PHRASES{$phrase} = 0;
        }
        close(FH);
    }
}

sub ngram_unload
{
    %PHRASES = ();
}

sub tagger
{
    my ($line, $size) = @_;
    my $result = '';
    my $token = '';


    return $line if ($size < 2);

    for (my $i = 0; $i < length($line); $i++) {
        my $here = substr($line, $i, 1);

        if ($here eq '[') {
            my $j;
            for ($j = 1; $j < length($line) - $i; $j++) {
                last if (substr($line, $i + $j, 1) eq ']');
            }

            $result .= substr($line, $i, $j + 1);
            $i += $j;
            next;
        }

        $token = substr($line, $i, $size);
        if (defined($PHRASES{$token})) {
            $PHRASES{$token}++;
            $KEYWORDS{$token} = 1;
            $result .= "[$token]";
            $i += $size - 1;
        }
        else {
            $result .= $here;
        }
    }

    tagger($result, $size - 1);
}

sub tagger_eng
{
    my $str = shift;
    my @tokens = grep { length($_) > 2 } split(/[^a-zA-Z0-9]/, $str);
    foreach (@tokens) {
        $_ = lc($_);
        $PHRASES{$_} = 0 unless defined($PHRASES{$_});
        $PHRASES{$_}++;
        $KEYWORDS{$_} = 1;
        print "*[$_] ";
    }
    print "\n";
}

sub cloud
{
    my @lists = getListNames();

    foreach my $list (@lists) {
        my %fields = getListFields($list);
        next unless ($fields{'VISI'} eq '1');
        next unless ($fields{'PUBL'} eq '1');
        foreach my $article (getPublishArticles($list)) {
            %KEYWORDS = ();
            my ($l, $a) = split(/\//, $article);
            my $subject = decode('utf-8', getDecodedSubjectFromFile("$SMARTLIST_PATH/$l/publish/$a"));
            tagger_eng($subject);
            $subject =~ s/\P{IsWord}/ /g;
            $subject = tagger(lc($subject), 10);
            print "$subject\n";
            my $file = "$SMARTLIST_PATH/www/cgi-bin/keywords/$l.$a";
            open(FH, ">:utf8", "$file");
            foreach (keys(%KEYWORDS)) {
                print FH "$_\n" if ($_);
            }
            close(FH);
        }
    }
}

sub ngram_count
{
    #umask(0000);
    open(FH, ">:utf8", "$DICT_PATH/freq");
    foreach (keys(%PHRASES)) {
        if ($PHRASES{$_} > 0) {
            print FH "$_ = $PHRASES{$_}\n";
        }
    }
    close(FH);
}

sub main
{
    ngram_load(10);

    cloud();

    ngram_count();
}

main();
