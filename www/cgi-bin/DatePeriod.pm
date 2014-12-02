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
BEGIN { $INC{'DatePeriod.pm'} ||= __FILE__ };

package DatePeriod;
use DateTime;

our @ISA = qw(Exporter);
our @EXPORT = qw(getDateRange
                );

my @PERIOD_INDEXES = qw(last all day week lastweek month lastmonth year);

sub getDateRange
{
    my ($period, $now) = @_;

    return (undef, undef) if (!defined($period));
    $now = time() if (!defined($now));

    my ($low, $high) = (undef, undef);
    my $dt = DateTime->from_epoch(epoch => $now);
    my $tmp_dt = $dt;

    if ($period eq 'day') {
        $tmp_dt->truncate(to => 'day');
        $low = $tmp_dt->epoch;
        $tmp_dt->add(days => 1);
        $high = $tmp_dt->epoch;
    }
    elsif ($period eq 'week') {
        $tmp_dt->truncate(to => 'week');
        $low = $tmp_dt->epoch;
        $tmp_dt->add(weeks => 1);
        $high = $tmp_dt->epoch;
    }
    elsif ($period eq 'last') {
        $tmp_dt->truncate(to => 'day');
        $tmp_dt->add(days => 1);
        $high = $tmp_dt->epoch;
        $tmp_dt->subtract(days => 14);
        $low = $tmp_dt->epoch;
    }
    elsif ($period eq 'lastweek') {
        $tmp_dt->truncate(to => 'week');
        $high = $tmp_dt->epoch;
        $tmp_dt->subtract(weeks => 1);
        $low = $tmp_dt->epoch;
    }
    elsif ($period eq 'month') {
        $tmp_dt->truncate(to => 'month');
        $low = $tmp_dt->epoch;
        $tmp_dt->add(months => 1);
        $high = $tmp_dt->epoch;
    }
    elsif ($period eq 'lastmonth') {
        $tmp_dt->truncate(to => 'month');
        $high = $tmp_dt->epoch;
        $tmp_dt->subtract(months => 1);
        $low = $tmp_dt->epoch;
    }
    elsif ($period eq 'year') {
        $tmp_dt->truncate(to => 'year');
        $low = $tmp_dt->epoch;
        $tmp_dt->add(years => 1);
        $high = $tmp_dt->epoch;
    }

    return ($low, $high);
}

#sub test
#{
#    foreach (@PERIOD_INDEXES) {
#        my @t = getDateRange($_);
#        use POSIX;
#        $t[0] =  strftime("%Y-%m-%d %H:%M:%S", localtime($t[0]));
#        $t[1] =  strftime("%Y-%m-%d %H:%M:%S", localtime($t[1]));
#        printf("%s %s %s\n", $_, $t[0], $t[1]);
#    }
#}
#test;

# lyshie_20080902: localtime +08:00
#last        2008-08-20 08:00:00    2008-09-03 08:00:00
#all         1970-01-01 08:00:00    1970-01-01 08:00:00
#day         2008-09-02 08:00:00    2008-09-03 08:00:00
#week        2008-09-01 08:00:00    2008-09-08 08:00:00
#lastweek    2008-08-25 08:00:00    2008-09-01 08:00:00
#month       2008-09-01 08:00:00    2008-10-01 08:00:00
#lastmonth   2008-08-01 08:00:00    2008-09-01 08:00:00
#year        2008-01-01 08:00:00    2009-01-01 08:00:00
