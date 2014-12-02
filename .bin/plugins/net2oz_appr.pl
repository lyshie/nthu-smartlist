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
use Encode qw(from_to);
use lib "$Bin";
use ListUtils;
use Data::Dump;
#

umask(0000);
my $SLIST_OLD_ACCOUNT = '/usr/local/list.net.nthu.edu.tw/cgi-bin/lists';
my $SLIST_OLD         = '/usr/local/list.net.nthu.edu.tw/slist';
my $CREATELIST = "$SMARTLIST_PATH/.bin/createlist";
my $MODERATE   = "$SMARTLIST_PATH/.bin/plugins/moderate.pl";
my $CONFIRM    = "$SMARTLIST_PATH/.bin/plugins/confirm.pl";
my $LISTS = "$Bin/lists.utf8";
my $SOURCES = "/usr/local/list.net.nthu.edu.tw/htdocs/approved";

sub net2oz
{
    my $ref = shift;
    my %fields = %$ref;
    my $list = $ref->{'NAME'};

    return if ($ref->{'NAME'} eq 'test');
    return if ($ref->{'NAME'} eq 'digest');

    if (-d "$SMARTLIST_PATH/" . $ref->{'NAME'}) {
        print "已存在目錄 " . $ref->{'NAME'} . "\n";
    }
    else {
        print "不存在目錄 " . $ref->{'NAME'} . "\n";

        if (system("$CREATELIST", $list, $fields{'MAIL'}) != 0) {
            print "無法建立電子報\n";
        }

        open(ALIASES, ">>$SMARTLIST_PATH/aliases");
        my $lines = <<EOF
$list: "|exec $MODERATE $list"
$list-request: "|exec $CONFIRM $list-request"
EOF
;
        print ALIASES $lines;
        close(ALIASES);
    }

    my $line = '';
    foreach (@SORTED_FIELDS) {
        $line .= "$fields{$_}:";
    }
    $line =~ s/:$/\n/;

    if (getListFields($ref->{'NAME'})) {
        setListFields($ref);
    }
    else {
        open(PASSWD, ">>$SMARTLIST_PASSWD");
        print PASSWD $line;
        close(PASSWD);
    }
}

sub net2oz_appr
{
    my $ref = shift;
    my %fields = %$ref;

    # copy approved
    return if ($ref->{'NAME'} eq 'test');
    return if ($ref->{'NAME'} eq 'digest');

    my $old_appr = "$SOURCES/" . $ref->{'NAME'}; 
    my $new_appr = "$SMARTLIST_PATH/" . $ref->{'NAME'} . "/approved";
    my $new_publish = "$SMARTLIST_PATH/" . $ref->{'NAME'} . "/publish";

    my $old_dist = "$SLIST_OLD/" . $ref->{'NAME'} . "/dist";
    my $new_dist = "$SMARTLIST_PATH/" . $ref->{'NAME'} . "/dist";

    return if (!-d "$SMARTLIST_PATH/" . $ref->{'NAME'});

    #system("/bin/rm", "-fr", $new_appr);
    #system("/bin/rm", "-fr", $new_publish);

    return if (!-d $old_appr);

    #unlink($new_dist) if (-f $new_dist);
    system("/bin/cp", "-f", $old_dist, $new_dist) if (-f $old_dist);
    
    #system("/bin/cp", "-pR",  $old_appr, $new_appr);
    system("/opt/csw/bin/rsync", "-avp",  "$old_appr/.", "$new_appr/");
    chmod(0770, $new_appr);

    opendir(DH, $new_appr);
    my @files = grep {-f "$new_appr/$_" } readdir(DH);
    closedir(DH);

    my @units = @files;

    @files = map { "$new_appr/$_" } @files;
    foreach (@files) {
        chmod(0660, $_);
    }

    mkdir($new_publish, 0770);
    foreach (@units) {
        symlink("$new_appr/$_", "$new_publish/$_");
    }
}

sub main
{
    my $buf = '';
    open(FH, $SLIST_OLD_ACCOUNT)
        || die die("ERROR: Can't open $SLIST_OLD_ACCOUNT\n");
        $buf .= $_ foreach (<FH>);
    close(FH);

    from_to($buf, 'big5', 'utf-8');

    my @lines = split(/[\n\r]+/, $buf);

    foreach (@lines) {
        chomp($_);
        my $line = $_;
        next if ($line =~ m/^#/);
        my %fields = ();
        ($fields{'VISI'}, $fields{'NAME'}, $fields{'DESC'}, $fields{'ORGA'},
         $fields{'MAIN'}, $fields{'MAIL'}, $fields{'PHON'}, $fields{'PUBL'}) =
               split(":", $line);
        $fields{'VISI'} = ($fields{'VISI'} + 1) % 2;
#        net2oz(\%fields);
        net2oz_appr(\%fields);
    }
}

main;
