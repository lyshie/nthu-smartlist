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
umask(0000);
$ENV{'PERL_RL'} = " o=0";
use FindBin qw($Bin);
use File::Basename;
use Term::ReadLine;
use lib "$Bin";
use ListUtils;
#
my $VERSION = '0.1.0';
my $DESCRIPTION = 'SmartList List Manager';
my $AUTHOR = 'Shie, Li-Yi <lyshie@mx.nthu.edu.tw>';
my $TERM;
my $OUT;
my $ALIVE = 1;
#
my $CREATELIST = "$SMARTLIST_PATH/.bin/createlist";
my $SUDO       = "/opt/csw/bin/sudo";
my $MODERATE   = "$SMARTLIST_PATH/.bin/plugins/moderate.pl";
my $CONFIRM    = "$SMARTLIST_PATH/.bin/plugins/confirm.pl";
#

sub showVersion;
sub showMenu;
sub showListInfo;
sub showAllListInfo;
sub showLists;
sub configureList;
sub newList;
sub deleteList;
sub showCommandLine;
sub removeData;

sub showVersion
{
    printf $OUT ("\n%s (v%s)\n作者：%s\n", $DESCRIPTION, $VERSION, $AUTHOR);
}

sub showMenu
{
    print $OUT "\n";
    print $OUT "n [LISTNAME]\t建立電子報\ti [LISTNAME]\t顯示電子報資訊\n" .
               "c [LISTNAME]\t設定電子報\tl\t\t列出所有電子報\n" .
               "d [LISTNAME]\t刪除電子報\ts [TYPE]\t顯示統計資訊\n" .
               "r (危險)\t清除過期資料\tb\t\t備份所有電子報\n" .
               "q\t\t離開管理系統\tg\t\t全域設定資訊\n" . 
               "v\t\t顯示版本資訊\th\t\t顯示說明\n";
}

sub showListInfo
{
    my $list = shift;
    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list eq '') {
        return;
    }

    my %fields = getListFields($list);
    if (%fields) {
        printf $OUT "\n";
        printf $OUT ("$FIELD_NAMES{'NAME'}:\t\t%s\n" .
                     "$FIELD_NAMES{'DESC'}:\t\t%s\n" .
                     "$FIELD_NAMES{'MAIN'}:\t\t%s\n" .
                     "$FIELD_NAMES{'ORGA'}:\t%s\n".
                     "$FIELD_NAMES{'MAIL'}:\t\t%s\n" .
                     "$FIELD_NAMES{'PHON'}:\t\t%s\n" .
                     "$FIELD_NAMES{'VISI'}:\t\t%s\n" .
                     "$FIELD_NAMES{'PUBL'}:\t\t%s\n",
                     $list, $fields{'DESC'}, $fields{'MAIN'},
                     $fields{'ORGA'}, $fields{'MAIL'}, $fields{'PHON'},
                     ($fields{'VISI'} eq '0') ? '否' : '是',
                     ($fields{'PUBL'} eq '0') ? '否' : '是',
                    );
    }
    else {
        printf $OUT ("\n電子報 [%s] 不存在！\n", $list);
    }
}

sub showAllListInfo
{
    my @names = getListNames();
    foreach (@names) {
        showListInfo($_);
    }
}

sub showLists
{
    my @names = getListNames();

    print $OUT "\n";
    foreach (@names) {
        printf $OUT ("%s\t", $_);
    }
    print $OUT "\n";
}

sub configureList
{
    my $list = shift;
    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list eq '') {
        return;
    }

    my %fields = getListFields($list);
    my $state = '';
    if (%fields) {
        while ($state eq '') {
            foreach my $key (@SORTED_FIELDS) {
                next if ($key eq 'NAME');
                my $buf = $TERM->readline("$FIELD_NAMES{$key}:($fields{$key}) > ");
                $fields{$key} = $buf if (defined($buf) && ($buf ne ''));
            }

            printf $OUT ("$FIELD_NAMES{'NAME'}:\t\t%s\n" .
                         "$FIELD_NAMES{'DESC'}:\t\t%s\n" .
                         "$FIELD_NAMES{'MAIN'}:\t\t%s\n" .
                         "$FIELD_NAMES{'ORGA'}:\t%s\n".
                         "$FIELD_NAMES{'MAIL'}:\t\t%s\n" .
                         "$FIELD_NAMES{'PHON'}:\t\t%s\n" .
                         "$FIELD_NAMES{'VISI'}:\t\t%s\n" .
                         "$FIELD_NAMES{'PUBL'}:\t\t%s\n",
                         $list, $fields{'DESC'}, $fields{'MAIN'},
                         $fields{'ORGA'}, $fields{'MAIL'}, $fields{'PHON'},
                         ($fields{'VISI'} eq '0') ? '否' : '是',
                         ($fields{'PUBL'} eq '0') ? '否' : '是',
                        );

            my $buf = $TERM->readline("是否要變更(y/n) ? ");
            $buf = 'n' if (!defined($buf) || ($buf eq ''));
            $state = lc($buf);
            if ($state eq 'y') {
                if (setListFields(\%fields)) {
                    print $OUT "\n完成變更電子報 [$list]\n";
                }
                else {
                    print $OUT "\n變更電子報 [$list] 期間發生錯誤！\n";
                }
            }
            else {
                $state = 'n';
            }
        }
    }
    else {
        printf $OUT ("\n電子報 [%s] 不存在，無法設定！\n", $list);
    }
}

sub newList
{
    my $list = shift;
    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list eq '') {
        return;
    }

    my @names = getListNames();
    foreach (@names) {
        if ($_ eq $list) {
            print $OUT "\n電子報 [$list] 已經存在！\n";
            last;
        }
    }

    my $buf = $TERM->readline("是否要建立電子報 [$list](y/n) ? ");
    $buf = 'n' if (!defined($buf) || ($buf eq ''));
    my $state = lc($buf);
    if ($state eq 'y') {
        print $OUT "\n建立電子報 [$list]...\n";

        my %fields = ('NAME' => $list,
                      'DESC' => '無',
                      'MAIN' => '無',
                      'ORGA' => '無',
                      'MAIL' => 'null@r309-2.cc.nthu.edu.tw',
                      'PHON' => '無',
                      'VISI' => '0',
                      'PUBL' => '0',
                     );

        if (system("$CREATELIST", $list, $fields{'MAIL'}) != 0) {
            print $OUT "\n無法建立電子報 [$list]！\n";
            return;
        }

        #umask(0000);
        open(FH, ">>$SMARTLIST_PATH/aliases");
        my $lines = <<EOF
$list: "|exec $MODERATE $list"
$list-request: "|exec $CONFIRM $list-request"
EOF
;
        print FH $lines;
        close(FH);

        my $line = '';
        foreach (@SORTED_FIELDS) {
            $line .= "$fields{$_}:";
        }
        $line =~ s/:$/\n/;

        #umask(0000);
        open(FH, ">>$SMARTLIST_PASSWD");
        print FH $line;
        close(FH);

        print $OUT "\n請輸入 root 密碼以建立新的 aliases\n";
        if (system("$SUDO", 'newaliases') != 0) {
            print $OUT "\n無法建立 aliases！\n";
            return;
        }

        if (!setListFields(\%fields)) {
            print $OUT "\n無法寫入 passwd！\n";
            return;
        }

        print $OUT "\n完成建立電子報 [$list]，請變更預設值\n";
        configureList($list);
    }
}

sub deleteList
{
    my $list = shift;
    my $old = $list;
    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list ne $old) {
        print $OUT "\n電子報 [$old] 名稱錯誤，無法刪除！\n";
        return;
    }

    my @names = getListNames();
    my $exist = 0;
    foreach (@names) {
        if ($list eq $_) {
            $exist = 1;
            last;
        }
    }
    if (!$exist) {
        print $OUT "\n電子報 [$list] 不存在，無法刪除！\n";
        return;
    }

    my $buf = $TERM->readline("是否要刪除電子報 [$list](y/n) ? ");
    $buf = 'n' if (!defined($buf) || ($buf eq ''));
    my $state = lc($buf);
    if ($state eq 'y') {
        if (removeList($list)) {
            print $OUT "\n完成刪除電子報 [$list]\n";

            print $OUT "\n請輸入 root 密碼以建立新的 aliases\n";
            if (system('sudo', 'newaliases') != 0) {
                print $OUT "\n無法建立 aliases！\n";
                return;
            }

            return;
        }
        else {
            print $OUT "\n刪除電子報 [$list] 失敗！\n";
            return;
        }
    }

    return;
}

sub removeData
{
    print $OUT "\n清除以下資料...\n";
    my @files = removeOutdatedData();

   foreach (@files) {
       print $OUT "unlink $_\n";
       unlink($_);
   }
}

sub showCommandLine
{
    my $command = $TERM->readline("smartlist> ");
    $command = '' if !defined($command);
    $command =~ s/^\s+//g;
    $command =~ s/\s+$//g;

    my @args = split(/\s+/, $command);

    $args[0] = defined($args[0]) ? $args[0] : '';
    $args[1] = defined($args[1]) ? $args[1] : '';

    my $action = lc($args[0]);
    my $param = $args[1];

    if ($action eq 'q') {
        $ALIVE = 0;
        print $OUT "\n再見！\n";
    }
    elsif ($action eq 'i') {
        if ($param eq '*') {
            showAllListInfo();
        }
        else {
            showListInfo($param);
        }
    }
    elsif ($action eq 'l') {
        showLists();
    }
    elsif ($action eq 'c') {
        configureList($param);
    }
    elsif ($action eq 'n') {
        newList($param);
    }
    elsif ($action eq 'd') {
        deleteList($param);
    }
    elsif ($action eq 'r') {
        removeData();
    }
    elsif ($action eq 'v') {
        showVersion();
    }
    elsif ($action eq 'h') {
        showMenu();
    }
    elsif ($action eq '?') {
        showMenu();
    }
    else {
        print $OUT "\n未知的指令！\n"; 
    }
}

sub main
{
    $TERM = new Term::ReadLine "$DESCRIPTION";
    $OUT = $TERM->OUT || \*STDOUT;

    showVersion();

    while ($ALIVE) {
        showCommandLine();
    }
}

main();
