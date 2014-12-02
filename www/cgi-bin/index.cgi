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
use ListTemplate;
use ListUtils;
use CGI qw(:standard);
use JQueryWidget;
use TagCloudWidget;
use ListQuery;
#
my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

sub main
{
    print header(-charset=> 'utf-8');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getDefaultMenu(),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetLatestArticles(),
                           'WIDGET_3' => getWidgetContainer(
                                             #getWidgetNTHUNews(),
                                             getWidgetTagCloud(),
                                             getWidgetCalendar("list.cgi",
                                                               param('m'),
                                                               param('y')),
                                             getWidgetClientInfo(),
                                             #getJQWidgetLoadAvg(),
                                             getWidgetValidation(),
                                         ),
                           'CONTENT'  => ListQuery::listApprovedArticles(
                                             'index.cgi', $sid),
                          }
                         );
}

main();
