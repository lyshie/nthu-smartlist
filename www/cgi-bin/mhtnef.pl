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
package m2h_tnef;

#
use MIME::Types;
use Convert::TNEF;
use Encode;
use Encode::Guess qw/big5-eten euc-cn/;

#
sub filter {
    my ( $fields, $data, $isdecode, $args ) = @_;

    my ( $fh, $tmpfile ) = mhonarc::file_temp( 'tnef_XXXXXXXXXX', "/tmp" );

    open( $fh, ">$tmpfile" );
    binmode($fh);
    print $fh $$data;
    close($fh);

    my ( $ret, $filename ) =
      processParts( $fields, $data, $isdecode, $args, $tmpfile );

    mhonarc::file_remove($tmpfile);

    # lyshie_20100617: winmail.dat contains no data
    if ( !$ret && !$filename ) {
        require "mhexternal.pl";
        ( $ret, $filename ) =
          m2h_external::filter( $fields, $data, $isdecode, $args );
    }

    return ( $ret, $filename );
}

sub _filter {
    my ( $fields, $data, $isdecode, $args, $mm_type, $fn, $tnef_data, $iext ) =
      @_;
    my ( $ret, $filename, $urlfile );
    require 'mhmimetypes.pl';

    ## Init variables
    $args = '' unless defined($args);
    my $name   = '';
    my $path   = '';
    my $subdir = $args =~ /\bsubdir\b/i;
    my $debug  = $args =~ /\bdebug\b/i;

    $mm_type   = defined($mm_type)   ? $mm_type   : '';    # content-type
    $fn        = defined($fn)        ? $fn        : '';    # filename
    $tnef_data = defined($tnef_data) ? $tnef_data : '';    # data
    $iext      = defined($iext)      ? $iext      : '';    # original extension

    my ( $ext, $description ) = mhonarc::get_mime_ext($mm_type);
    if ( ( $ext eq 'bin' ) && ( $iext ne '' ) ) {
        $ext = $iext;
    }

    ## Check if file goes in a subdirectory
    $path = join( '', $mhonarc::MsgPrefix, $mhonarc::MHAmsgnum )
      if $subdir;

    ## Write file
    ( $filename, $urlfile ) = mhonarc::write_attachment(
        $mm_type,
        \$tnef_data,
        {
            '-dirpath' => $path,
            '-ext'     => $ext,
        }
    );
    &debug("File-written: $filename") if $debug;

    ## Create HTML markup
    my $desc      = '<em>Description:</em> ';
    my $namelabel = '';

    $desc .= mhonarc::htmlize( $description || $mm_type );

    if ($filename) {
        $namelabel = $fn;
        $namelabel =~ s/^.*$mhonarc::DIRSEPREX//o;
        mhonarc::htmlize( \$namelabel );
    }

    my $frame = $args =~ /\bframe\b/;
    if ( !$frame ) {
        $ret = <<EOT;
<p><strong>Attachment:
<a href="$urlfile"><tt>$namelabel</tt></a></strong><br />
$desc</p>
EOT
    }
    else {
        $ret = <<EOT;
<table border="1" cellspacing="0" cellpadding="4">
<tr><td><strong>Attachment:
<a href="$urlfile"><tt>$namelabel</tt></a></strong><br />
$desc</td></tr></table>
EOT
    }

    return ( $ret, $path || $filename );
}

##---------------------------------------------------------------------------

sub debug {
    local ($_);
    foreach (@_) {
        print STDERR "m2h_tnef: ", $_;
        print STDERR "\n" unless /\n$/;
    }
}

##---------------------------------------------------------------------------

sub processParts {
    my ( $fields, $data, $isdecode, $args, $tmpfilename ) = @_;

    my ( $ret, $filename );

    # TNEF (winmail.dat)
    my $tnef = Convert::TNEF->read_in($tmpfilename);

    return unless ($tnef);

    ## iterate tnef parts and attach
    my @attachments = $tnef->attachments();
    foreach my $t (@attachments) {
        my ($ext) = ( $t->longname =~ /\.([A-Za-z]{2,4})$/ );
        my $mimetypes = MIME::Types->new();
        my $mm_type   = $mimetypes->mimeTypeOf($ext)
          || "application/octet-stream";
        my $fn = encode( "utf-8", decode( "Guess", $t->longname ) );

        my ( $r, $f ) =
          _filter( $fields, $data, $isdecode, $args, $mm_type, $fn, $t->data,
            $ext );

        $ret      .= $r;
        $filename .= $f;
    }

    $tnef->purge();

    return ( $ret, $filename );
}

##---------------------------------------------------------------------------
1;
