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
use FindBin qw($Bin);
use lib "$Bin";
use ListUtils;
use ourSession;
use CGI qw(:standard);
#
my $MHONARC          = '/opt/csw/bin/mhonarc';
my $ATTACHMENTS_PATH = "$SMARTLIST_PATH/www/htdocs/attachments";
my $ATTACHMENTS_URL  = '/slist/attachments';

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

my ($list, $article, $mode) = ($listname, '', '');

sub getParams
{
    #$list    = param('list') || '';
    $article = param('article') || '';
    $list    =~ s/[^\w\-]//g;
    $article =~ s/[^\d]//g;

    $mode = param('mode') || '';

    if (($list eq '') || ($article eq ''))  {
    }
}

sub getViewContent
{
    my %fields = getListFields($list);
    #return unless ($fields{'VISI'} eq '1');
    #return unless ($fields{'PUBL'} eq '1');

    my $file = "$SMARTLIST_PATH/$list/approved/$article";
    my $rcfile = 'default_s.mrc';

    if ($mode eq 'moderate') {
        $file = "$SMARTLIST_PATH/$list/moderate/$article";
    }

    my $result = '';

    if (-f $file) {
        if ($list eq 'netsys') {
            $rcfile = 'default_s.netsys.mrc';
        }
        else {
        }
        $result = `$MHONARC -rcfile $rcfile -nourl -nomailto -nomsgpgs -nodecodeheads -noprintxcomments -single -attachmentdir $ATTACHMENTS_PATH -attachmenturl $ATTACHMENTS_URL $file`;
    }

    return $result;
}

sub main
{
    getParams();
    print header(-charset=>'utf-8');
    print getViewContent();
}

main();
