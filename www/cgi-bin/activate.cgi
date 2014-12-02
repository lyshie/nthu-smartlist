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
use ListCheck;
use CGI qw(:standard);
use File::Basename;
#
my $sid = param('sid')    || '';
$sid =~ s/[^0-9a-zA-Z]//g;

my $action        = '';
my $uid           = '';
my $email         = '';
my $username      = '';
my $host          = '';
my $password      = '';
my @subscriptions = ();

my $RAND_MAX      = 999999;
my $UID           = time() . int(rand($RAND_MAX));
my $SENDMAIL      = "/usr/sbin/sendmail -oi -f DO-NOT-REPLY\@" . getListDomain();
my $LISTS_PATH    = "$Bin/lists";

my $REMOTE_ADDR   = defined($ENV{'REMOTE_ADDR'}) ? $ENV{'REMOTE_ADDR'} : '';
my $REMOTE_HOST   = defined($ENV{'REMOTE_HOST'}) ? $ENV{'REMOTE_HOST'} : '';
my $REQUEST_URI   = defined($ENV{'REQUEST_URI'}) ? $ENV{'REQUEST_URI'} : '';

sub getActivateContent
{
    my ($act, $id) = @_;

    my $result = <<EOF
<h2>電子報訂閱/取消訂閱結果</h2>
<br />
<code>
EOF
;

    if (($act eq 'subscribe') && ($id =~ m/^s\d+$/)) {
        my $file = "$LISTS_PATH/$id";
        my $email = '';
        my @lists = ();

        if (-f $file) {
            open(FH, "$file");
            $email = <FH>;
            chomp($email);
            while (<FH>) {
                chomp;
                push(@lists, $_);
            }
            close(FH);
            unlink($file);

            $result .= "您已完成訂閱電子報，清單如下：\n";
            if ($email ne '') {
                foreach my $list (@lists) {
                    my %fields = getListFields($list);
                    addDist($list, $email);
                    removeUnneeded($list, [$email]);
                    $result .= " [$list] $fields{'DESC'}\n";
                }
            }
        }
        else {
            $result .= "訂閱需求不存在！\n";
        }
    }
    elsif (($act eq 'unsubscribe') && ($id =~ m/^u\d+$/)) {
        my $file = "$LISTS_PATH/$id";
        my $email = '';
        my @lists = ();

        if (-f $file) {
            open(FH, "$file");
            $email = <FH>;
            chomp($email);
            while (<FH>) {
                chomp;
                push(@lists, $_);
            }
            close(FH);
            unlink($file);

            $result .= "您已取消訂閱電子報，清單如下：\n";
            if ($email ne '') {
                foreach my $list (@lists) {
                    my %fields = getListFields($list);
                    removeDist($list, $email);
                    addUnneeded($list, [$email]);
                    $result .= " [$list] $fields{'DESC'}\n";
                }
            }
        }
        else {
            $result .= "取消訂閱需求不存在！\n";
        }
    }
    else {
        $result .= "沒有動作"
    }


    $result .= <<EOF
</code>
<br />
<div align="center">
<a href="subscribe2.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;

    return $result;
}

sub getParams
{
    $action = param('action') || '';
    $uid    = param('uid')    || '';

    $action =~ s/[^a-z]//g;
    $uid    =~ s/[^su0-9]//g;
}

sub main
{
    getParams();

    print header(-charset=>'utf-8', -expires => 'now');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getDefaultMenu(),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetLatestArticles(),
                           'WIDGET_3' => getNull(),
                           'CONTENT'  => getActivateContent($action, $uid),
                          }
                         );
}

main();
