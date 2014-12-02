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
use ListLog;
use ourSession;
use File::Basename;
use Unix::Syslog qw(:macros :subs);
#

my ($list, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;

sub _logout
{
    syslog(LOG_INFO,
           "Logout. (sid=%s)",
           $sid
          );

    logToList($list,
              "[%s] LOGOUT (%s)",
              basename($0),
              $sid
             );

    sessionDelete();
}

sub main
{
    openlog(basename($0), LOG_PID, LOG_LOCAL5);

    _logout();

    closelog();
}

main();
