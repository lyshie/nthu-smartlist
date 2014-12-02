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
#

sub getStatusContent
{
    my $result = <<EOF
<h2>統計資料</h2>
<br />
<h3>一、本月發行紀錄</h3>
<div class="shadowed">
<img src="/slist/images/graph/bar_this_month.png" alt="本月發行統計圖表" />
</div>
<div>
&nbsp;
</div>
<h3>二、今年總發行紀錄</h3>
<div class="shadowed">
<img src="/slist/images/graph/bar_this_year.png" alt="今年總發行統計圖表" />
</div>
<div>
&nbsp;
</div>
<h3>三、所有發行紀錄</h3>
<div class="shadowed">
<img src="/slist/images/graph/bar_total.png" alt="全部發行統計圖表" />
</div>
<br />
<div align="center">
<a href="javascript:history.back()">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub main
{
    print header(-charset=>'utf-8');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getDefaultMenu(),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetLatestArticles(),
                           'WIDGET_3' => getWidgetContainer(
                                             getWidgetCalendar("list.cgi",
                                                               param('m'),
                                                               param('y')),
                                             getWidgetValidation(),
                                         ),
                           'CONTENT'  => getStatusContent(),
                          }
                         );
}

main();
