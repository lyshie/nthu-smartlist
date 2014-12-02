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
use FindBin qw($Bin);
use lib "$Bin";
use ListUtils;
use Mail::Internet;
use MIME::Words qw(:all);
use XML::RSS;
use HTML::Entities;
use POSIX qw(strftime mktime);
use Email::Date;
use Date::Parse;
#

my $URL       = "http://" . getListDomain();
my $RSS_PATH  = "$SMARTLIST_PATH/www/htdocs/rss";
my $INTRO_URL = "$URL/slist/cgi-bin/intro.cgi";

my $TODAY = 0;
my $RSS;

#sub getArticles
#{
#    my $list = shift;
#    my $path = "$SMARTLIST_PATH/$list/publish";
#    my @articles = ();
#    if (-d $path) {
#        opendir(DH, $path);
#        @articles = grep { -f "$path/$_" } readdir(DH);
#        closedir(DH);
#    }
#
#    return @articles;
#}

sub RSSBegin
{
    my $list = shift;

    my $lastBuildDate = format_date(time());
    my %fields = getListFields($list);
    my $domain = getListDomain();

    $RSS = undef;
    $RSS = new XML::RSS (version => '2.0',
                         encode_output => 0,
                        );
    $RSS->channel(
        title         => "[$fields{'NAME'}] $fields{'DESC'}", 
        link          => "$INTRO_URL?list=$fields{'NAME'}",
        description   => $fields{'DESC'},
        lastBuildDate => $lastBuildDate,
        dc => {
            creator   => "slist\@$domain (slist)",
            publisher => "slist\@$domain (slist)",
            rights    => 'Copyright 2008, Computer and Communication Center, NTHU.',
            language  => 'zh-tw',
        },
    );
}

sub RSSAddItem
{
    my ($list, $article, $subject, $date) = @_; 
    $RSS->add_item(
        title => encode_entities("$subject", '<>&"'),
        link  => "$URL/slist/cgi-bin/view.cgi?article=$article&amp;list=$list",
        pubDate => format_date($date),
        mode => "insert",
        permaLink => "$URL/slist/cgi-bin/view.cgi?article=$article&amp;list=$list",
    );
}

sub RSSEnd
{
    my $list = shift;
    #umask(0000);
    open(FH, ">$RSS_PATH/$list.xml");
    #print $RSS->as_string;
    print FH $RSS->as_string();
    close(FH);
}

sub getArticlesByDay
{
    my @lists = getListNames();
    my @articles = ();

    my $subject = '';
    my $approved_date = '';

    # clean all RSS files
    opendir(DH, $RSS_PATH);
    my @files = grep { -f "$RSS_PATH/$_" &&
                       m/\.xml$/ } readdir(DH);

    closedir(DH);
    foreach (@files) {
        next if ($_ eq 'nthu.xml'); 
        next if ($_ eq 'latest.xml'); 
        unlink("$RSS_PATH/$_");
        printf("unlink $RSS_PATH/$_\n");
    }

    foreach my $list (@lists) {
        my %fields = getListFields($list);
        # lyshie_20080326: the list should !hidden and public
        next if ($fields{'VISI'} eq '0');
        next if ($fields{'PUBL'} eq '0');

        RSSBegin($list);

        @articles = getPublishArticles($list);
        @articles = sort { ctimePublish($a) <=> ctimePublish($b) } @articles;
        foreach my $a (@articles) {
            my ($l, $article) = split(/\//, $a);
            $subject = '';
            $approved_date = '';

            my @MSGS = ();
            open(FH, "$SMARTLIST_PATH/$list/publish/$article");
            while (<FH>) {
                my $line = $_;
                chomp($line);
                last if ($line eq '');
                push(@MSGS, $line);
            }
            close(FH);

            my $mail = Mail::Internet->new(\@MSGS);
            my $MAIL_HEADER = $mail->head();
            $subject = $MAIL_HEADER->get('subject');
            $subject = getDecodedSubject($subject);
            chomp($subject);
            #$approved_date = $MAIL_HEADER->get('date') || '';
            #chomp($approved_date);
            #$approved_date = str2time($approved_date) || 0;
            $approved_date = ctimePublish($a) || 0;

            if (($TODAY - $approved_date) < 86400 * 90) {
                #printf("%s %s\n", $subject, $approved_date);
                RSSAddItem($list, $article, $subject, $approved_date);
            }
        }

        RSSEnd($list);
    }
}

sub main
{
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime();

    $TODAY = mktime(0, 0, 0, $mday, $mon, $year);

    getArticlesByDay();
}

main();
