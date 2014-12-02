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
use ListLog;
use ourSession;
use Unix::Syslog qw(:macros :subs);
use CGI qw(:standard);
use File::Basename;
#

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

my $TARGET = '';

sub getSwitchContent
{
    my $options = '';

    my %fields = getListFields($listname);

    my @names = getListNames();

    foreach my $n (sort @names) {
        next if ($listname eq $n);

        my %f = getListFields($n);
        next if ($fields{'MAIL'} ne $f{'MAIL'}); # the original list maintainer

        $options .= qq{\n\t\t\t<option value="$n">[$n] $f{'DESC'}</option>};
    }

    my $result = <<EOF
<h2>切換電子報</h2>
<br />
<form action="switch.cgi" method="post">
<input type="hidden" name="sid" value="$sid" />
<table class="light" align="center">
	<tr>
		<td class="lightheader">電子報管理者：</td>
		<td class="light">
                    $fields{'MAIL'}
		</td>
	</tr>
	<tr>
		<td class="lightheader">目前的電子報：</td>
		<td class="light">
                    [$listname] $fields{'DESC'}
		</td>
	</tr>
	<tr>
		<td class="lightheader">欲切換的電子報：</td>
		<td class="light">
			<select name="target">
                        $options
			</select>
		</td>
	</tr>
	<tr>
		<td class="light" colspan="2" style="text-align: center;">
			<input type="submit" name="action" value="切換電子報" />
		</td>
	</tr>
</table>
</form>
<br />
<div align="center">
<a href="admin.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub switchListName
{
    my ($target) = @_;

    my %fields        = getListFields($listname);
    my %target_fields = getListFields($target);

    if ($fields{'MAIL'} eq $target_fields{'MAIL'}) { # match, success
        sessionSet($sid, 'listname', $target);
    }
}

sub getParams
{
    $TARGET = defined(param('target')) ? param('target') : '';
    $TARGET =~ s/[^\w\-]//g;
}

sub main
{
    openlog(basename($0), LOG_PID, LOG_LOCAL5);

    getParams();

    if ($TARGET ne '') { # has target name and switch it
        switchListName($TARGET);
	print redirect(-uri => "switch.cgi?sid=$sid");
    }
    else {
        print header(-charset=>'utf-8');
        print templateReplace('index.ht',
                              {'TITLE'    => getDefaultTitle(),
                               'TOPIC'    => getDefaultTopic(),
                               'MENU'     => getAdminMenu($sid),
                               'WIDGET_1' => getWidgetSearch(),
                               'WIDGET_2' => getWidgetLatestArticles(),
                               'WIDGET_3' => getWidgetSession(),
                               'CONTENT'  => getSwitchContent(),
                              }
                             );
    }
    closelog();
}

main();
