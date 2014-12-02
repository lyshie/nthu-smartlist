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
use CGI qw(:standard);
use HTML::Entities;
use MIME::Parser;
use MIME::Types;
use Convert::TNEF;
use Encode;
use Encode::Guess qw/big5-eten euc-cn/;
#

my %ICONS = (
              "default"                       => "file.png",
              "application/pdf"               => "pdf.png",
              "application/msword"            => "doc.png",
              "application/x-msword"          => "doc.png",
              "application/vnd.ms-powerpoint" => "ppt.png",
              "application/octet-stream"      => "bin.png",
              "image/jpeg"                    => "jpeg.png",
              "image/gif"                     => "gif.png",
              "image/bmp"                     => "image.png",
              "image/png"                     => "png.png",
              "text/html"                     => "html.png",
              "text/htm"                      => "htm.png",
            );

my $EXTRACT_PATH = "$SMARTLIST_PATH/www/htdocs/extract";
my $EXTRACT_URL  = "/slist/extract";
my $SELECT_BEGIN = <<EOF
<b>附件列表：</b><select class="edit" name="actionmenu" onchange=
	"if ((this.selectedIndex != 0) &amp;&amp;
	(this.options[this.selectedIndex].disabled == false)) {
	location.href = this.options[this.selectedIndex].value;
	}
this.selectedIndex = 0;" >
  <option value="show">--附件列表--</option>
EOF
;

my $SELECT_END = q{
</select>
};

sub extractMail
{
    my ($list, $article) = @_;
    my $filename = "$SMARTLIST_PATH/$list/publish/$article";
    my $result = '';
    $result .= $SELECT_BEGIN;
    if (-f $filename) {
        my $parser = new MIME::Parser;
        $parser->output_under("/tmp");
        my @entities = ();
        my $entity =  $parser->parse_open($filename);
        @entities = $entity->parts_DFS();
        for my $e (@entities) {
            my $fn = $e->head()->recommended_filename();
            my $mm_type = $e->mime_type() || 'default';

            if ($mm_type =~ m/ms\-tnef/i) {
                $result .= processParts($list, $article, $e);
                next;
            }

            if (defined($fn)) {
                $fn = getDecodedSubject($fn);
                $fn =~ s/[\\\/\?\*]//xmsg;
                $fn =~ s/\.\.//xmsg;
                my $url_fn = encode_entities(qq{$EXTRACT_URL/$list\_$article\_$fn}, q{<>&"'});
                my $real_fn = qq{$EXTRACT_PATH/$list\_$article\_$fn};
                my $icon = $ICONS{$mm_type} || $ICONS{'default'};
                $fn = encode_entities($fn, q{<>&"'});
                open(FN, ">$real_fn");
                print FN $e->bodyhandle()->as_string;
                close(FN);
                $result .= qq{<option value="$url_fn" style="background: url('$EXTRACT_URL/icons/$icon') no-repeat; padding-left: 20px;">$fn ($mm_type)</option>};
            }
        }
    }
    $result .= $SELECT_END;

    return $result;
}

sub processParts {
    my ($list, $article, $entity) = @_;
    my $result = '';

    # Multi-Parts
    if ( $entity->parts ) {
        foreach my $part ( $entity->parts ) {
            processParts($list, $article, $part);
        }
    }
    # TNEF (winmail.dat)
    elsif ( $entity->mime_type =~ /ms\-tnef/i ) {
        my $tnef = Convert::TNEF->read_ent( $entity );

        return $result unless ($tnef);

        ## iterate tnef parts and attach
        my @attachments = $tnef->attachments;
        foreach my $t ( @attachments ) {
            my $mimetypes = MIME::Types->new;
            my ($ext) = ( $t->longname =~ /\.([A-Za-z]{2,4})$/ );
            my $mm_type = $mimetypes->mimeTypeOf($ext)
              || "application/octet-stream";
            my $fn = encode( "utf-8", decode( "Guess", $t->longname ) );

            if ( defined($fn) ) {
                $fn = getDecodedSubject($fn);
                $fn =~ s/[\\\/\?\*]//xmsg;
                $fn =~ s/\.\.//xmsg;
                my $url_fn =
                  encode_entities( qq{$EXTRACT_URL/$list\_$article\_$fn},
                    q{<>&"'} );
                my $real_fn = qq{$EXTRACT_PATH/$list\_$article\_$fn};
                my $icon = $ICONS{$mm_type} || $ICONS{'default'};
                $fn = encode_entities( $fn, q{<>&"'} );
                open( FN, ">$real_fn" );
                print FN $t->data;
                close(FN);
                $result .=
qq{<option value="$url_fn" style="background: url('$EXTRACT_URL/icons/$icon') no-repeat; padding-left: 20px;">$fn ($mm_type)</option>};
            }
        }

        $tnef->purge();
    }

    return $result;
}

1;
