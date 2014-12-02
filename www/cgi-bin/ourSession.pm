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
BEGIN { $INC{'ourSession.pm'} ||= __FILE__ };

package ourSession;

use Exporter;
use CGI qw(:standard);
use CGI::Session;
use File::stat;
use FindBin qw($Bin);
use lib "$Bin";
use ListTemplate;
use ListUtils;

our @ISA = qw(Exporter);
our @EXPORT = qw(sessionCheck
                 sessionNew
                 sessionSet
                 sessionDelete
                 sessionIPBlocking
                 sessionNotAllow
                );

our $SID;

sub getNotAllowContent
{
    my $addr = $ENV{'REMOTE_ADDR'} || '';
    my $result = <<EOF
<h2>連線來源被拒絕</h2>
<br />
<code>
您的連線來源 ($addr) 被拒絕，請在限定範圍內連線！
<span class="alert">限本校 IP 登入管理，校外可使用 <a href="http://net.nthu.edu.tw/2009/sslvpn:info" target="_blank">TWAREN SSL-VPN</a></span>
</code>
EOF
;
    return $result;
}

sub sessionNotAllow
{
    print header(-charset=>'utf-8');
    print ListTemplate::templateReplace('index_redirect.ht',
                          {'META'     => ListTemplate::getRedirectMeta('index.cgi', 10),
                           'TITLE'    => ListTemplate::getDefaultTitle(),
                           'TOPIC'    => ListTemplate::getDefaultTopic(),
                           'MENU'     => ListTemplate::getDefaultMenu(),
                           'WIDGET_1' => ListTemplate::getNull(),
                           'WIDGET_2' => ListTemplate::getNull(),
                           'WIDGET_3' => ListTemplate::getNull(),
                           'CONTENT'  => getNotAllowContent(),
                          }
                         );
    exit(0);
}

sub getExpireContent
{
    my $result = <<EOF
<h2>連線逾時</h2>
<br />
<code>
您的連線已逾時，<a href="login.cgi">請按這裡重新登入</a>！
</code>
EOF
;
    return $result;
}

sub sessionExpire
{
    print header(-charset=>'utf-8');
    print ListTemplate::templateReplace('index_redirect.ht',
                          {'META'     => ListTemplate::getRedirectMeta('login.cgi', 3),
                           'TITLE'    => ListTemplate::getDefaultTitle(),
                           'TOPIC'    => ListTemplate::getDefaultTopic(),
                           'MENU'     => ListTemplate::getDefaultMenu(),
                           'WIDGET_1' => ListTemplate::getWidgetSearch(),
                           'WIDGET_2' => ListTemplate::getNull(),
                           'WIDGET_3' => ListTemplate::getNull(),
                           'CONTENT'  => getExpireContent(),
                          }
                         );
    exit(0);
}

sub getEmptyContent
{
    my $result = <<EOF
<h2>連線不存在</h2>
<br />
<code>
您尚未連線，<a href="login.cgi">請按這裡重新登入</a>！
</code>
EOF
;
    return $result;
}

sub sessionEmpty
{
    # show not login
    print header(-charset => 'utf-8');
    print ListTemplate::templateReplace('index_redirect.ht',
                          {'META'     => ListTemplate::getRedirectMeta('login.cgi', 1),
                           'TITLE'    => ListTemplate::getDefaultTitle(),
                           'TOPIC'    => ListTemplate::getDefaultTopic(),
                           'MENU'     => ListTemplate::getDefaultMenu(),
                           'WIDGET_1' => ListTemplate::getWidgetSearch(),
                           'WIDGET_2' => ListTemplate::getNull(),
                           'WIDGET_3' => ListTemplate::getNull(),
                           'CONTENT'  => getEmptyContent(),
                          }
                         );
    exit(0);
}

sub sessionCheckError
{
    # show internal error
    # provide login
    sessionEmpty();
    #exit(0);
}

sub sessionFree
{
    my ($path, $lifetime) = @_;
    opendir(DH, $path);
    my @sessions = grep { -f "$path/$_" && m/^cgisess_/ } readdir(DH);
    close(DH);

    my $now = time();
    eval {
        foreach (@sessions) {
            my $st = stat("$path/$_");
            if ( ($now - $st->atime()) > $lifetime ) {
                unlink("$path/$_");
            }
        }
    };
}

sub checkMaintainer
{
    my ($u, $h, $l) = ('', '', '');
    ($u, $h, $l) = @_;

    my $ret = 0;

    return 1 if ("$u\@$h" eq getListMaintainer($l));

    return $ret;
}

sub checkAdministrator
{
    my ($u, $h) = ('', '');
    ($u, $h) = @_;

    my $ret = 0;
    my $email = "$u\@$h";

    my @admins = ();
    open(FH, "$Bin/administrators");
    foreach my $line (<FH>) {
        chomp($line);
        next if ($line =~ m/^#/);
        push(@admins, $line);
    }
    close(FH);

    foreach my $a (@admins) {
        if ($a eq $email) {
            $ret = 1;
            last;
        }
    }

    return $ret;
}

sub sessionCheck
{
    # you can comment the below line to cancel the check
    sessionIPBlocking();

    $SID = param('sid') || '';
    $SID =~ s/[^0-9a-zA-Z]//g;

    my $s = CGI::Session->load("driver:file;serializer:FreezeThaw;id:md5",
                               $SID,
                               {'Directory' => "$Bin/tmp"}
                              );

    if (!defined($s) || $s->is_expired()) {
        sessionExpire();
    }

    if ($s->is_empty()) {
        sessionEmpty();
    }

    my ($u, $p, $h, $l) = ($s->param('username'),
                           $s->param('password'),
                           $s->param('hostname'),
                           $s->param('listname')
                          );

    if (!checkMaintainer($u, $h, $l) && !checkAdministrator($u, $h)) {
        sessionCheckError();
        return;
    }

    return ($l, $SID, $u, $h);
}

sub sessionNew
{
    my ($u, $p, $h, $l) = @_;

    my $s = new CGI::Session("driver:file;serializer:FreezeThaw;id:md5",
                             undef,
                             {'Directory' => "$Bin/tmp"}
                            );
    $s->param('username', $u);
    $s->param('password', $p);
    $s->param('hostname', $h);
    $s->param('listname', $l);
    $s->expire('1800s');
    $s->flush();

    # lyshie_20070107: for security reason, free unused sessions
    #                  after 1 hour (3600 seconds)
    sessionFree("$Bin/tmp", 60 * 60);

    # lyshie_20080827: check whether if the list exists
    if (!getListFields($l)) {
        sessionCheckError();
        return;
    }

    # lyshie_20080827: early check to prevent the action as login
    if (!checkMaintainer($u, $h, $l) && !checkAdministrator($u, $h)) {
        sessionCheckError();
        return;
    }

    return $s->id();
}

sub sessionSet {
    my ( $sid, $key, $value ) = @_;

    my $s = new CGI::Session("driver:file;serializer:FreezeThaw;id:md5",
                             $sid,
                             {'Directory' => "$Bin/tmp"}
                            );

    my $result;
    $result = $s->param( $key, $value );
    $s->flush();

    return $result;
}

sub getDeleteContent
{
    my $result = <<EOF
<h2>已完成登出</h2>
<br />
<code>
您已完成登出，<a href="login.cgi">請按這裡重新登入</a>！
</code>
EOF
;
    return $result;
}

sub sessionDelete
{
    $SID = param('sid') || '';
    $SID =~ s/[^0-9a-zA-Z]//g;

    my $s = CGI::Session->load("driver:file;serializer:FreezeThaw;id:md5",
                               $SID,
                               {'Directory' => "$Bin/tmp"}
                              );
    $s->delete();

    print header(-charset => 'utf-8');
    print ListTemplate::templateReplace('index_redirect.ht',
                          {'META'     => ListTemplate::getRedirectMeta('login.cgi', 1),
                           'TITLE'    => ListTemplate::getDefaultTitle(),
                           'TOPIC'    => ListTemplate::getDefaultTopic(),
                           'MENU'     => ListTemplate::getDefaultMenu(),
                           'WIDGET_1' => ListTemplate::getWidgetSearch(),
                           'WIDGET_2' => ListTemplate::getNull(),
                           'WIDGET_3' => ListTemplate::getNull(),
                           'CONTENT'  => getDeleteContent(),
                          }
                         );
    exit(0);
}

sub sessionIPBlocking
{
    my $file = "$Bin/hosts.allow";
    my @hosts = ();
    my $allow = 0;

    if (-f $file) {
        open(FH, $file);
        foreach my $host (<FH>) {
            chomp($host);
            push(@hosts, $host);
        }
        close(FH);
        my $addr = $ENV{'REMOTE_ADDR'} || '';

        foreach (@hosts) {
            if (index($addr, $_) == 0) {
                $allow = 1;
                last;
            }
        }

        if ($allow == 1) {
            return;
        }
        else {
            sessionNotAllow();
        }

    }
    else {
        return;
    }
}

1;
