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
BEGIN { $INC{'JQueryWidget.pm'} ||= __FILE__ };

package JQueryWidget;

our @ISA = qw(Exporter);
our @EXPORT = qw(getJQWidgetLoadAvg
                );

sub getJQWidgetLoadAvg
{
    my $result = <<EOF
<!-- auto-generated -->
	<script type="text/javascript" src="/slist/js/jquery/plugins/jquery.timer.js"></script>
	<script type="text/javascript" src="/slist/js/widgets/loadavg.js"></script>
<div class="widget">
<h4>系統負載</h4>
<br />
<table class="light" width="100%" id="loadavg">
<tr class="listheader"><td>1分鐘</td><td>5分鐘</td><td>15分鐘</td></tr>
<tr class="list"><td id="avg1"></td><td id="avg5"></td><td id="avg15"></td></tr>
</table>
</div>
<!-- auto-generated -->
EOF
;
    return $result;
}
