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
use lib "$Bin";
use ListUtils;
use CGI qw(:standard);
#
my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my $MHONARC          = '/opt/csw/bin/mhonarc';
my $ATTACHMENTS_PATH = "$SMARTLIST_PATH/www/htdocs/attachments";
my $ATTACHMENTS_URL  = '/slist/attachments';
my $CACHE_PATH       = "$SMARTLIST_PATH/www/htdocs/cache";

my ($list, $article, $mode) = ('', '', '');

sub getParams
{
    $list    = param('list') || '';
    $article = param('article') || '';
    $mode    = param('mode') || '';

    $list    =~ s/[^\w\-]//g;
    $article =~ s/[^\d]//g;
    $mode    =~ s/[^\w]//g;

    if (($list eq '') || ($article eq '')) {
    }
}

sub getViewContent
{
    my %fields = getListFields($list);
    return unless ($fields{'VISI'} eq '1');
    return unless ($fields{'PUBL'} eq '1');

    my $file = "$SMARTLIST_PATH/$list/publish/$article";
    my $rcfile = 'default.mrc';
    my $result = '';

    my $cache_file = "$CACHE_PATH/$list.$article";

    if (-f $file) {
        if (-f $cache_file) {
            open(FH, $cache_file);
            $result .= $_ foreach (<FH>);
            close(FH);
        }
        else {
            if ($list eq 'netsys') {
                $rcfile = 'default.netsys.mrc';
            }
            else {
                $result .= '<base target="_blank" />' . "\n";
            }
            $result .= `$MHONARC -rcfile $rcfile -nourl -nomailto -nomsgpgs -nodecodeheads -noprintxcomments -single -attachmentdir $ATTACHMENTS_PATH -attachmenturl $ATTACHMENTS_URL $file`;
            #umask(0000);
            open(FH, ">$cache_file");
            print FH $result;
            close(FH);
        }
    }

    # lyshie_20080827: add antispam support
    my $tmp = '';
    my $antispam = 0;
    foreach my $line (split(/[\n\r]/, $result)) {
        $antispam = 1 if ($line eq '<!--X-Subject-Header-Begin-->');
        $antispam = 0 if ($line eq '<!--X-Subject-Header-End-->');
        if ($antispam == 1) {
            $line =~ s/\./<img src="\/slist\/images\/dot.png" style="vertical-align: bottom;" alt="(dot)" \/>/g;
            $line =~ s/\@/<img src="\/slist\/images\/at.png" style="vertical-align: bottom;" alt="(at)" \/>/g;
        }
        $tmp .= "$line\n";
    }
    $result = $tmp;


    if ($mode eq 'print') {
        my $printfile = "$Bin/print.txt";
        my $buffer = '';
        open(FH, $printfile);
        while (<FH>) {
            $buffer .= $_;
        }
        close(FH);
        $buffer =~ s/#MAIL#/$result/gm;

        return $buffer;
    }
    else {
        return $result;
    }
}

sub main
{
    getParams();
    print header(-charset=>'utf-8');
    print getViewContent();
}

main();
