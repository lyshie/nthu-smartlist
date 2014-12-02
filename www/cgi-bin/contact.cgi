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

sub getContactContent
{
    my $todo = '';
    open(FH, "$Bin/TODO");
    while (<FH>) {
        $_ =~ s/\t+\[.*\]$//g;
        $todo .= $_;
    }
    close(FH);

    my $result = <<EOF
<h2>聯絡資訊</h2>
<br />
<code>
<span class="green">1. 電子報刊物問題</span>
您如果有電子報<span class="alert">刊物內容</span>或訂閱<span class="alert">特定電子報</span>問題，請洽<a href="archives.cgi">各電子報管理者</a>。

<span class="green">2. 訂閱系統的問題</span>
您如果有訂閱系統的問題請 mail 至 <a href="mailto:slist\@list.net.nthu.edu.tw?subject=訂閱系統的問題">slist\@list.net.nthu.edu.tw</a>。

<span class="green">3. 管理系統的問題</span>
您如果有管理系統的問題請 mail 至 <a href="mailto:slist\@list.net.nthu.edu.tw?subject=管理系統的問題">slist\@list.net.nthu.edu.tw</a>。
</code>
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
                           'CONTENT'  => getContactContent(),
                          }
                         );
}

main();
