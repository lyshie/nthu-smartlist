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
umask(0000);
use CGI qw(:standard);
use GD::SecurityImage;
use File::Basename;
use Unix::Syslog qw(:macros :subs);
use FindBin qw($Bin);
use LWP::UserAgent;

my @RND_DATA = ('0'..'9');
my $VALIDATE_PATH = "/tmp/validate";

my ($URL, $LANG) = ('', '');

sub createImageAndVoice
{
    my $image = GD::SecurityImage->new(
                    width => 100,
                    height => 30,
                    lines => 2,
                    font =>
                        "$Bin/ARABOLIC.ttf",
                    #    "$Bin/ACE.ttf",
                    #    "$Bin/PakTypeNaqsh.ttf",
                    ptsize => 14,
                    rndmax => 6,
                    rnd_data => \@RND_DATA);

    $image->random();
    $image->create(ttf => "box", '#37313d', '#a0da2b');
    $image->particle(200, 1);
    my ($image_data, $mime_type, $random_number) = $image->out;

    mkdir ($VALIDATE_PATH) unless (-d $VALIDATE_PATH);
    #umask(0000);
    open(FH, ">$VALIDATE_PATH/$random_number");
    print FH time();
    close(FH);

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->get("$URL?content=$random_number");
    binmode STDOUT;
    # lyshie_20080626: must expire the page, some browsers will cache it (opera)
    print header(-type => "audio/mpeg", -expires => 'now');
    if ($response->is_success) {
        print $response->content;
    }

    my $addr = $ENV{'REMOTE_ADDR'} || '';
    syslog(LOG_INFO, "Generate random number (tts). (number=%s, remote_addr=%s)",
           $random_number,
           $addr
          );
}

sub getParams
{
    $LANG = param('lang') || '';
    $LANG =~ s/[^a-zA-Z]//g;
    $LANG = lc($LANG);

    if ($LANG eq 'zh') {
        $URL = "http://op7.oz.nthu.edu.tw/cgi-bin/voice_zh.pl";
    }
    elsif ($LANG eq 'tw') {
        $URL = "http://op7.oz.nthu.edu.tw/cgi-bin/voice_tw.pl";
    }
    else {
        $URL = "http://op7.oz.nthu.edu.tw/cgi-bin/voice.pl";
    }
}

sub main
{
    openlog(basename($0), LOG_PID, LOG_LOCAL5);
    getParams();
    createImageAndVoice();
    closelog();
}

main();
