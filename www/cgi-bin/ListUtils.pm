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
BEGIN { $INC{'ListUtils.pm'} ||= __FILE__ };

package ListUtils;
umask(0000);
use File::Copy;
use File::Remove qw(remove);
use Text::Iconv;
use MIME::Words qw(:all);
use Mail::Internet;
use Unix::Syslog qw(:macros :subs);

our @ISA = qw(Exporter);
our @EXPORT = qw($SMARTLIST_PATH
                 $SMARTLIST_PASSWD
                 %FIELD_NAMES
                 @SORTED_FIELDS
                 @ACCEPT_HOSTS
                 %ACCEPT_POP3_HOSTS
                 ctimePublish
                 ctimeApproved
                 ctimeModerate
                 getListDomain
                 getListMaintainer
                 getListFields
                 getListNames
                 setListFields
                 setListMaintainer
                 removeList
                 getDists
                 addDist
                 importDists
                 removeDist
                 checkDuplicated
                 removeOutdatedData
                 getPublishArticles
                 getLatestPublishArticles
                 getApprovedArticles
                 getModerateArticles
                 getSubject
                 getDecodedSubject
                 getDecodedSubjectFromFile
                 addUnneeded
                 removeUnneeded
                 getUnneeded
                );

our $SMARTLIST_PATH   = '/usr/local/slist';
our $SMARTLIST_PASSWD = "$SMARTLIST_PATH/passwd";
our @SORTED_FIELDS    = ('NAME', 'DESC', 'MAIN', 'ORGA',
                         'MAIL', 'PHON', 'VISI', 'PUBL'
                        );
our %FIELD_NAMES    = ('NAME' => '名稱',
                       'DESC' => '敘述',
                       'MAIN' => '管理者',
                       'ORGA' => '單位組織',
                       'MAIL' => '信箱',
                       'PHON' => '電話',
                       'VISI' => '可見',
                       'PUBL' => '公開',
                      );

our @ACCEPT_HOSTS  = ('mx.nthu.edu.tw',
                      'my.nthu.edu.tw',
                      'oz.nthu.edu.tw',
                      'm98.nthu.edu.tw',
                      'm99.nthu.edu.tw',
                      'm100.nthu.edu.tw',
                      'm101.nthu.edu.tw',
                      'm102.nthu.edu.tw',
                      'm103.nthu.edu.tw',
                     );

our %ACCEPT_POP3_HOSTS = ('mx.nthu.edu.tw'   => 'pop.mx.nthu.edu.tw',
                          'my.nthu.edu.tw'   => 'pop.my.nthu.edu.tw',
                          'oz.nthu.edu.tw'   => 'pop.oz.nthu.edu.tw',
                          'm98.nthu.edu.tw'  => 'pop.m98.nthu.edu.tw',
                          'm99.nthu.edu.tw'  => 'pop.m99.nthu.edu.tw',
                          'm100.nthu.edu.tw' => 'pop.m100.nthu.edu.tw',
                          'm101.nthu.edu.tw' => 'pop.m101.nthu.edu.tw',
                          'm102.nthu.edu.tw' => 'pop.m102.nthu.edu.tw',
                          'm103.nthu.edu.tw' => 'pop.m103.nthu.edu.tw',
                         );

sub getSubject
{
    my $filename = shift;
    my $subject = '';
    return $subject unless (-f $filename);

    my @msgs = ();
    open(FH, $filename);
    while (<FH>) {
        my $line = $_;
        chomp($line);
        last if ($line eq '');
        push(@msgs, $line);
    }
    close(FH);

    my $mail = Mail::Internet->new(\@msgs);
    my $MAIL_HEADER = $mail->head();

    my $ret = $MAIL_HEADER->get('subject');
    chomp($ret);
    return $ret;
}

sub getDecodedSubject
{
    my ($msg, $default_charset) = @_;
    $default_charset = defined($default_charset) ?
                           $default_charset : 'UTF-8';

    chomp($msg);
    my @subjects = decode_mimewords($msg);

    my $subject = '';
    foreach (@subjects) {
        my $charset = $_->[1] || 'BIG-5';

        # lyshie_20090917: fixed the missing charsets for GB
        if ($charset =~ m/gb(18030|k|2312)/i) {
            $charset = 'cp936';
        }

        my $data = $_->[0] || '';
        my $converter = Text::Iconv->new($charset, $default_charset);
        $subject .= $converter->convert($data) || '';
    }

    return $subject;
}

sub getDecodedSubjectFromFile
{
    my ($filename, $default_charset) = @_;
    $default_charset = defined($default_charset) ?
                           $default_charset : 'UTF-8';

    my @subjects = decode_mimewords(getSubject($filename));

    my $subject = '';
    foreach (@subjects) {
        my $charset = $_->[1] || 'BIG-5';

        # lyshie_20090917: fixed the missing charsets for GB
        if ($charset =~ m/gb(18030|k|2312)/i) {
            $charset = 'cp936';
        }

        my $data = $_->[0] || '';
        my $converter = Text::Iconv->new($charset, $default_charset);
        $subject .= $converter->convert($data) || '';
    }

    return $subject;
}

sub ctimePublish
{
    my ($list, $article) = split(/\//, $_[0]);
    return (stat("$SMARTLIST_PATH/$list/publish/$article"))[9]; 
}

sub ctimeApproved
{
    my ($list, $article) = split(/\//, $_[0]);
    return (stat("$SMARTLIST_PATH/$list/approved/$article"))[9];
}

sub ctimeModerate
{
    my ($list, $article) = split(/\//, $_[0]);
    return (stat("$SMARTLIST_PATH/$list/moderate/$article"))[9];
}

sub getListDomain
{
    my $domain = '';
    my $file = "$SMARTLIST_PATH/.etc/rc.init";
    if (-f $file) {
        open(FH, $file);
        foreach my $line (<FH>) {
            chomp($line);
            if ($line =~ m/^\s*domain\s*=\s*([\d\w\-\_\.]+)/) {
                $domain = $1 if defined($1);
                last;
            }
        }
        close(FH);
    }

    return $domain;
}

sub getListMaintainer
{
    my $listname = shift;
    my $maintainer = '';

    my $file = "$SMARTLIST_PATH/$listname/rc.custom";
    if (-f $file) {
        open(FH, $file);
        foreach my $line (<FH>) {
            chomp($line);
            if ($line =~ m/^\s*maintainer\s*=\s*([\d\w\-\_\@\.]+)/) {
                $maintainer = $1 if defined($1);
                last;
            }
        }
        close(FH);
    }

    return $maintainer;
}

sub setListMaintainer
{
    my ($listname, $maintainer) = @_;

    my $ret = 0;

    my $file = "$SMARTLIST_PATH/$listname/rc.custom";

    my @items = ();

    if (-f $file) {
        open(FH, $file);
        @items = <FH>;
        close(FH);

        for (my $i = 0; $i < @items; $i++) {
            my $line = $items[$i];
            chomp($line);
            if ($line =~ m/^\s*maintainer\s*=\s*([\d\w\-\_\@\.]+)/) {
                $line = "maintainer\t=\t$maintainer\n";
                $items[$i] = $line;
                $ret = 1;
                last;
            }
        }
    }

    #umask(0000);
    open(FH, ">$file");
        foreach (@items) {
            print FH $_;
        }
    close(FH);

    return $ret;
}

sub getListFields
{
    my $list = shift;
    my @result = ();
    my %ret = ();

    my @items = ();
    open(FH, $SMARTLIST_PASSWD);
    @items = <FH>;
    close(FH);

    my @fields = ();
    foreach my $item (@items) {
        chomp($item);
        $item =~ s/^\s+//g;
        if (($item eq '') || ($item =~ m/^#/)) {
            next;
        }
        @fields = split(/:/, $item);
        if ($fields[0] eq $list) {
            @result = @fields;
            last;
        }
    }

    if (@result > 0) {
        $ret{'NAME'} = $list;
        $ret{'DESC'} = defined($result[1]) ? $result[1] : '';
        $ret{'MAIN'} = defined($result[2]) ? $result[2] : '';
        $ret{'ORGA'} = defined($result[3]) ? $result[3] : '';
        $ret{'MAIL'} = defined($result[4]) ? $result[4] : '';
        $ret{'PHON'} = defined($result[5]) ? $result[5] : '';
        $ret{'VISI'} = defined($result[6]) ? $result[6] : '0';
        $ret{'PUBL'} = defined($result[7]) ? $result[7] : '0';
    }

    return %ret;
}

sub getListNames
{
    my @ret = ();

    my @items = ();

    if (-f $SMARTLIST_PASSWD) {
        open(FH, $SMARTLIST_PASSWD);
        @items = <FH>;
        close(FH);
    }

    foreach my $item (@items) {
        chomp($item);
        $item =~ s/^\s+//g;
        if (($item eq '') || ($item =~ m/^#/)) {
            next;
        }
        my ($name) = split(/:/, $item);
        push(@ret, $name) if (defined($name) && ($name ne ''));
    }

    return @ret;
}

sub setListFields
{
    my $fields = shift;
    my $ret = 0;

    $fields->{'MAIL'} =~ s/[^\d\w\-\_\.\@]//g;
    $fields->{'VISI'} = ($fields->{'VISI'} eq '0') ? '0' : '1';
    $fields->{'PUBL'} = ($fields->{'PUBL'} eq '0') ? '0' : '1';

    my @items = ();
    open(FH, $SMARTLIST_PASSWD);
    @items = <FH>;
    close(FH);

    my @fields = ();
    for (my $i = 0; $i < @items; $i++) {
        my $item = $items[$i];
        chomp($item);
        $item =~ s/^\s+//g;
        if (($item eq '') || ($item =~ m/^#/)) {
            next;
        }

        my @tokens = split(/:/, $item);
        if ($tokens[0] eq $fields->{'NAME'}) {
            $item = '';
            foreach (@SORTED_FIELDS) {
                $fields->{$_} =~ s/://g;
                $item .= "$fields->{$_}:";
            }
            $item =~ s/[\n\r]//g;
            $item =~ s/:$/\n/;
            $items[$i] = $item;
            last;
        }
    }

    if (!setListMaintainer($fields->{'NAME'}, $fields->{'MAIL'})) {
        return $ret;
    }

    # lyshie_20080729: set umask to 0000 for postfix bad pipe
    #umask(0000);
    open(FH, ">$SMARTLIST_PASSWD.tmp");
    foreach (@items) {
        print FH $_;
    }
    close(FH);

    my $suffix = time();
    if ((-f "$SMARTLIST_PASSWD.tmp") && (-f $SMARTLIST_PASSWD)) {
        copy($SMARTLIST_PASSWD, "$SMARTLIST_PASSWD.$suffix");
        if (-f "$SMARTLIST_PASSWD.$suffix") {
            if (unlink($SMARTLIST_PASSWD)) {
                copy("$SMARTLIST_PASSWD.tmp", $SMARTLIST_PASSWD);
                if (-f "$SMARTLIST_PASSWD") {
                    unlink("$SMARTLIST_PASSWD.tmp");
                    $ret = 1;
                }
            }
        }
    }

    return $ret;
}

sub removeList
{
    my $list = shift;
    my $old = $list;

    my $ret = 0;

    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list ne $old) {
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
    return if !$exist;

    my @aliases = ();
    open(FH, "$SMARTLIST_PATH/aliases");
    @aliases = <FH>;
    close(FH);

    #umask(0000);
    open(FH, ">$SMARTLIST_PATH/aliases");
    foreach my $alias (@aliases) {
        my $line = $alias;
        chomp($line);
        if ($line =~ m/^\Q$list\E:.*$/) {
        }
        elsif ($line =~ m/^\Q$list\E\-request:.*$/) {
        }
        else {
            print FH $alias;
        }
    }
    close(FH);

    my $suffix = time();
    copy($SMARTLIST_PASSWD, "$SMARTLIST_PASSWD.$suffix");
    if (!-f "$SMARTLIST_PASSWD.$suffix") {
        return;
    }

    my @items = ();
    open(FH, "$SMARTLIST_PASSWD");
    @items = <FH>;
    close(FH);

    #umask(0000);
    open(FH, ">$SMARTLIST_PASSWD");
    foreach my $item (@items) {
        my $line = $item;
        chomp($line);
        if ($line =~ m/^\Q$list\E:.*$/) {
        }
        else {
            print FH $item;
        }
    }
    close(FH);

    $ret = remove(\1, "$SMARTLIST_PATH/$list");

    return $ret;
}

sub getDists
{
    my $list = shift;
    my $old = $list;

    my @fixed = ();
    my @auto  = ();
    my @all   = ();

    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list ne $old) {
        return;
    }

    my $file = "$SMARTLIST_PATH/$old/dist";

    if (!-f $file) {
        return;
    }

    open(FH, $file);
    @all = <FH>;
    close(FH);

    my $fix = 1;
    foreach my $line (@all) {
        chomp($line);
        if ($line eq
            '(Only addresses below this line can be automatically removed)') {
            $fix = 0;
            next;
        }

        if ($fix) {
            push(@fixed, $line);
        }
        else {
            push(@auto, $line);
        }
    }

    return (\@fixed, \@auto);
}

# lyshie_20080520: flag(0) => atuo, flag(1) => fixed
sub addDist
{
    my ($list, $email, $flag) = @_;
    $flag = 0 if (!defined($flag) || ($flag eq ''));
    my $old = $list;

    my %fixed = ();
    my %auto  = ();
    my @all   = ();

    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list ne $old) {
        return;
    }

    my $file = "$SMARTLIST_PATH/$old/dist";

    if (!-f $file) {
        return;
    }

    open(FH, $file);
    @all = <FH>;
    close(FH);

    my $fix = 1;
    foreach my $line (@all) {
        chomp($line);
        if ($line eq
            '(Only addresses below this line can be automatically removed)') {
            $fix = 0;
            next;
        }

        if ($fix) {
            $fixed{$line} = 0;
        }
        else {
            $auto{$line} = 0;
        }
    }

    if ($flag eq '0') {
        $auto{$email} = 0;
    }
    else {
        $fixed{$email} = 0;
    }

    @all = ();
    push (@all, keys(%fixed));
    push (@all,
          '(Only addresses below this line can be automatically removed)');
    push(@all, keys(%auto));

    #umask(0000);
    open(FH, ">$file");
    foreach (@all) {
        print FH "$_\n";
    }
    close(FH);
}

# lyshie_20080520: flag(0) => append, flag(1) => replace
sub importDists
{
    my ($list, $emails, $flag) = @_;
    $flag = 0 if (!defined($flag) || ($flag eq ''));
    my $old = $list;

    my %fixed = ();
    my %auto  = ();
    my @all   = ();

    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list ne $old) {
        return;
    }

    my $file = "$SMARTLIST_PATH/$old/dist";

    if (!-f $file) {
        return;
    }

    open(FH, $file);
    @all = <FH>;
    close(FH);

    my $fix = 1;
    foreach my $line (@all) {
        chomp($line);
        if ($line eq
            '(Only addresses below this line can be automatically removed)') {
            $fix = 0;
            next;
        }

        if ($flag ne '1') {
            if ($fix) {
                $fixed{$line} = 0;
            }
            else {
                $auto{$line} = 0;
            }
        }
    }

    foreach (@$emails) {
        $auto{$_} = 0;
    }

    @all = ();
    push (@all, keys(%fixed));
    push (@all,
          '(Only addresses below this line can be automatically removed)');
    push(@all, keys(%auto));

    #umask(0000);
    open(FH, ">$file");
    foreach (@all) {
        print FH "$_\n";
    }
    close(FH);

    return @all;
}

# lyshie_20080520: disable this function
sub checkDuplicated
{
#    my @all = @_;
#    my @uniqs = ();

#    my $isadd = 1;
#    for (my $i = 0; $i < @all; $i++) {
#        $isadd = 1;
#        for (my $j = 0; $j < $i; $j++) {
#            if ($all[$i] eq $all[$j]) {
#                $isadd = 0;
#                last;
#            }
#        }
#        if ($isadd == 1) {
#            push(@uniqs, $all[$i]);
#        }
#    }

#   return @uniqs;
}

# lyshie_20080520: flag(0) => auto, flag(1) => fixed
sub removeDist
{
    my ($list, $email, $flag) = @_;

    my $emails;
    if (ref($email) ne 'ARRAY') {
        my @tmp = ($email);
        $emails = \@tmp;
    }
    else {
        $emails = $email;
    }

    $flag = 0 if (!defined($flag) || ($flag eq ''));
    my $old = $list;
    my $is_removed = 0;

    my %auto  = ();
    my %fixed = ();
    my @all   = ();

    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list ne $old) {
        return;
    }

    my $file = "$SMARTLIST_PATH/$old/dist";

    if (!-f $file) {
        return;
    }

    open(FH, $file);
    @all = <FH>;
    close(FH);

    my $fix = 1;
    foreach my $line (@all) {
        chomp($line);
        if ($line eq
            '(Only addresses below this line can be automatically removed)') {
            $fix = 0;
            next;
        }

        if ($fix) {
            $fixed{$line} = 0;
        }
        else {
            $auto{$line} = 0;
        }
    }

    if ($flag eq '0') {
        foreach my $e (@$emails) {
            if (defined($auto{$e})) {
                $is_removed = 1;
                delete($auto{$e});
            }
        }
    }
    else {
        foreach my $e (@$emails) {
            if (defined($fixed{$e})) {
                $is_removed = 1;
                delete($fixed{$e});
            }
        }
    }

    @all = ();
  
    push (@all, keys(%fixed));
    push (@all,
          '(Only addresses below this line can be automatically removed)');
    push(@all, keys(%auto));


    #umask(0000);
    open(FH, ">$file");
    foreach (@all) {
        print FH "$_\n";
    }
    close(FH);

    return ($is_removed, @all);
}

sub removeOutdatedData
{
    my @files = ();

    my @lists = sort(getListNames());

    my $dir = '';
    my @fs = ();
    my @dirs = ();

    $dir = "$SMARTLIST_PATH";
    opendir(DH, $dir);
    @fs = grep {-f "$dir/$_" && m/passwd\.\d+/} readdir(DH);
    closedir(DH);
    foreach (@fs) {
        push(@files, "$dir/$_");
    }

    foreach my $list (@lists) {
        # lyshie_20080901: remove confirm
        $dir = "$SMARTLIST_PATH/$list/confirm";
        if (-d $dir) {
            opendir(DH, $dir);
            @fs = grep {-f "$dir/$_" } readdir(DH);
            closedir(DH);
            foreach (@fs) {
                push(@files, "$dir/$_");
            }
        }

        # lyshie_20080901: remove moderate
        $dir = "$SMARTLIST_PATH/$list/moderate";
        if (-d $dir) {
            opendir(DH, $dir);
            @fs = grep {-f "$dir/$_" } readdir(DH);
            closedir(DH);
            foreach (@fs) {
                push(@files, "$dir/$_");
            }
        }
    }

    # lyshie_20080901: remove attachments, cache
    @dirs = ("$SMARTLIST_PATH/www/htdocs/attachments",
             "$SMARTLIST_PATH/www/htdocs/cache",
           );

    foreach $dir (@dirs) {
        if (-d $dir) {
            opendir(DH, $dir);
            @fs = grep {-f "$dir/$_" && !m/index.htm.*/ } readdir(DH);
            closedir(DH);
            foreach (@fs) {
                push(@files, "$dir/$_");
            }
        }
    }

    return @files;
}

sub getPublishArticles
{
    my $listname = shift;
    my %fields = getListFields($listname);
    return unless ($fields{'VISI'} eq '1');

    my @articles = (); # store the result
    my $path = "$SMARTLIST_PATH/$listname/publish"; # easy to use

    if (-d $path) {
        opendir(DH, $path);
        @articles = grep { -f "$path/$_" && m/\d+/ } readdir(DH);
        closedir(DH);
    }

    return map("$listname/$_", @articles);
}

sub getLatestPublishArticles
{
    my $period = shift;
    $period = defined($period) ? $period : 7;
    my @lists = getListNames();
    my @articles = ();
    foreach my $list (@lists) {
        push(@articles, getPublishArticles($list));
    }

    @articles = grep { (time() - ctimePublish($_) < 86400 * $period)  }
                     @articles;

    return reverse sort { ctimePublish($a) <=> ctimePublish($b) } @articles;
}

sub getApprovedArticles
{
    my $listname = shift;
    my %fields = getListFields($listname);
    return unless ($fields{'VISI'} eq '1');

    my @articles = (); # store the result
    my $path = "$SMARTLIST_PATH/$listname/approved"; # easy to use
    opendir(DH, $path);
    @articles = grep { -f "$path/$_" && m/\d+/ } readdir(DH);
    closedir(DH);

    return map("$listname/$_", @articles);
}

sub getModerateArticles
{
    my $listname = shift;
    my %fields = getListFields($listname);
    return unless ($fields{'VISI'} eq '1');

    my @articles = (); # store the result
    my $path = "$SMARTLIST_PATH/$listname/moderate"; # easy to use
    opendir(DH, $path);
    @articles = grep { -f "$path/$_" && m/\d+/ } readdir(DH);
    closedir(DH);

    return map("$listname/$_", @articles);
}

sub addUnneeded
{ # parameters: $email => reference of array
    my $old   = shift || return;
    my $email = shift;

    my $list = $old;

    # check the listname before and after
    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    # if not equal, there is a problem with the listname
    if ($list ne $old) {
        return;
    }

    # the filename to store unneeded e-mail
    my $file = "$SMARTLIST_PATH/$list/unneeded";

    # the new added e-mails
    my %emails = ();
    foreach (@$email) {
        $emails{$_} = 1;
    }

    # dump the original e-mails into memory
    if (-f $file) {
        open(FH, $file);
            foreach my $line (<FH>) {
                chomp($line);
                $emails{$line} = 1;
            }
        close(FH);
    }

    # combine and write back
    # lyshie_20080729: set umask to 0000 for postfix bad pipe
    #umask(0000);
    open(FH, ">$file");
        foreach (keys(%emails)) {
            printf FH ("%s\n", $_);
        }
    close(FH);
}

sub removeUnneeded
{
    # parameters: $email => reference of array
    my $old   = shift || return;
    my $email = shift;

    my $list = $old;

    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list ne $old) {
        return;
    }

    my $file = "$SMARTLIST_PATH/$list/unneeded";

    my %emails = ();

    if (-f $file) {
        open(FH, $file);
        foreach my $line (<FH>) {
            chomp($line);
            $emails{$line} = 1;
        }
        close(FH);
    }

    foreach (@$email) {
        $emails{$_} = 0;
    }

    #umask(0000);
    open(FH, ">$file");
        foreach (keys(%emails)) {
            if ($emails{$_} == 1) {
                printf FH ("%s\n", $_);
            }
        }
    close(FH);
}

sub getUnneeded
{
    my $old = shift || return;

    my $list = $old;

    $list =~ s/[^\w\-]//g;
    $list =~ s/^\-+//g;
    $list =~ s/\-+$//g;

    if ($list ne $old) {
        return;
    }

    my $file = "$SMARTLIST_PATH/$list/unneeded";

    my %emails = ();

    if (-f $file) {
        open(FH, $file);
        foreach my $line (<FH>) {
            chomp($line);
            $emails{$line} = 1;
        }
        close(FH);
    }

    return keys(%emails);
}
