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
#use ourSession;
use ListUtils;
use CGI qw(:standard);
#

my $sid = param('sid') || '';
$sid =~ s/[^0-9a-zA-Z]//g;

#my ($listname, $sid) = sessionCheck();

sub getStatusContent
{
    my $result = <<EOF
<script type="text/javascript" src="/slist/flowplayer/examples/js/flashembed.min.js"></script>
<script type="text/javascript">
	flashembed("view", {
		src: '/slist/flowplayer/FlowPlayerDark.swf',
		width: 400,
		height: 290
		},
		{ config: {
			showVolumeSlider: false,
			controlsOverVideo: 'ease',
			controlBarGloss: 'low',
			autoPlay: false,
			autoBuffering: true,
			initialScale: 'scale',
			loop: false,
			videoFile: '/slist/flowplayer/movies/view.flv'
			}
		}
        );

	flashembed("subscribe", {
		src: '/slist/flowplayer/FlowPlayerDark.swf',
		width: 400,
		height: 290
		},
		{ config: {
			showVolumeSlider: false,
			controlsOverVideo: 'ease',
			controlBarGloss: 'low',
			autoPlay: false,
			autoBuffering: true,
			initialScale: 'scale',
			loop: false,
			videoFile: '/slist/flowplayer/movies/subscribe.flv'
			}
		}
	);

	flashembed("query", {
		src: '/slist/flowplayer/FlowPlayerDark.swf',
		width: 400,
		height: 290
		},
		{ config: {
			showVolumeSlider: false,
			controlsOverVideo: 'ease',
			controlBarGloss: 'low',
			autoPlay: false,
			autoBuffering: true,
			initialScale: 'scale',
			loop: false,
			videoFile: '/slist/flowplayer/movies/query.flv'
			}
		}
	);
</script>
<h2>操作說明</h2>
<br />
EOF
;

    $result .= <<EOF
<h4>瀏覽電子報</h4>
<div id="view"></div>
<h4>訂閱電子報</h4>
<div id="subscribe"></div>
<h4>查詢訂閱情形</h4>
<div id="query"></div>
<br />
<h2>說明文件</h2>
<ul>
<li><a href="http://net.nthu.edu.tw/2009/slist" target="_blank">新版電子報系統介紹</a></li>
<li><a href="http://net.nthu.edu.tw/2009/faq#mailing" target="_blank">電子報常見問題</a></li>
<li><a href="/slist/files/mailinglist_20090319.pdf">2009/03/20 新版電子報操作投影片</a></li>
<li><a href="/slist/files/mailinglist_20070418.pdf">2007/04/18 舊版電子報操作投影片</a></li>
<li><a href="/slist/files/mailinglist_20070418_bw.pdf">2007/04/18 舊版電子報操作投影片 (列印)</a></li>
<li><a href="/slist/files/mailinglist_20070314.pps">2007/03/14 舊版電子報操作投影片</a></li>
</ul>
EOF
;

    $result .= <<EOF
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
                           'WIDGET_2' => getNull(),
                           'WIDGET_3' => getNull(),
                           'CONTENT'  => getStatusContent(),
                          }
                         );
}

main();
