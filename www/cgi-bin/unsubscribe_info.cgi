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
use CGI qw(:standard);
#
my $list = param('list') || '';
$list    =~ s/[^\w\-]//g;

sub main
{
    my %hash = getListFields($list);
    print header(-expires  => 'now',
                 -charset  => 'utf-8',
#                 -type     => 'text/plain',
                 -type     => 'application/x-download',
                 -filename => "退訂資訊_unsubscribe_$list.txt",
                 -content_disposition => "inline; filename=退訂資訊_unsubscribe_$list.txt",
                );

    if (%hash) {

        print <<EOF
本信件由『[$hash{'NAME'}] $hash{'DESC'}』寄出，
如欲取消訂閱請至：
http://list.net.nthu.edu.tw/slist/cgi-bin/unsubscribe.cgi?lists=$list

If you want to unsubscribe from the mailing list [$hash{'NAME'}],
please click this link:
http://list.net.nthu.edu.tw/slist/cgi-bin/unsubscribe.cgi?lists=$list
EOF
;

    }
}

main();
