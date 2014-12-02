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
use ourSession;
use ListUtils;
use CGI qw(:standard);
use Email::Valid;
#

my ($listname, $sid) = sessionCheck();
$sid =~ s/[^0-9a-zA-Z]//g;


sub check_email {
    my ($list) = @_;

    my @result = ();

    my $dist_file = "$SMARTLIST_PATH/$list/dist";

    if (!-f $dist_file) {
        return @result;
    }

    open(FH, $dist_file);
    while (<FH>) {
        my $email = $_;
        chomp($email);
        next if ($email =~ m/^#/);
        next if ($email eq '(Only addresses below this line can be automatically removed)');
        unless (Email::Valid->address($email)) {
            push(@result, $email);
        }
    }
    close(FH);

    return @result;
}

sub getEditDistContent
{
    my ($f, $a) = getDists($listname);
    my $fixed = '';
    my $auto = '';
    $fixed .= "$_\n" foreach (@$f);
    $auto .= "$_\n" foreach (@$a);


    # lyshie_20080902: for auto-complete use
    my @dists = @$a;

    my $upload = '';
    $upload .= start_multipart_form(-name => 'upload',
                                    -method => 'post',
                                    -action => 'upload.cgi');
    $upload .= hidden(-name => 'sid',
                      -value => $sid);
    $upload .= filefield(-name      => 'uploaded_file',
                         -default   => 'starting value',
                         -size      => 50,
                         -maxlength => 80);
    $upload .= submit(-value => '上傳清單');
    $upload .= endform();

    my $invalid_email = join("\n", check_email($listname));

    my $result = <<EOF
<h2>編輯訂戶清單</h2>
<br />
<table class="light" width="90%" align="center">
	<tr class="listheader">
		<td colspan="1">上傳訂戶清單</td>
	</tr>
	<tr class="list">
		<td colspan="1" align="center">
		<p><span class="alert">(上傳後，系統將自動增加而非覆蓋)</span></p>
		$upload
		</td>
	</tr>
	<tr class="listheader">
		<td>編輯訂戶清單</td>
	</tr>
	<tr class="list">
<!--		<td>
			<form action="upload.cgi" method="post">
			<input type="hidden" name="sid" value="$sid" />
			<input type="hidden" name="action" value="fixed" />
			<textarea cols="30" rows="15" name="dists"></textarea>
			<input type="submit" value="更新" />
			</form>
		</td>
-->
		<td>
			<form action="upload.cgi" method="post">
			<input type="hidden" name="sid" value="$sid" />
 			<input type="hidden" name="action" value="auto" />
			<textarea name="dists" id="dists" cols="48" rows="5"></textarea>
			<input type="submit" value="加入" />
			</form>
			<br />
			<form action="upload.cgi" method="post">
			<input type="hidden" name="sid" value="$sid" />
 			<input type="hidden" name="action" value="remove" />
			<textarea name="rdists" id="rdists" cols="48" rows="5">$invalid_email</textarea>
			<input type="submit" value="刪除" />
			</form>
<!-- auto-complete -->
<script type="text/javascript" src="/slist/js/jquery/plugins/autocomplete/lib/jquery.bgiframe.min.js"></script>
<script type="text/javascript" src="/slist/js/jquery/plugins/autocomplete/lib/jquery.dimensions.js"></script>
<script type="text/javascript" src="/slist/js/jquery/plugins/autocomplete/jquery.autocomplete.js"></script>
<script type="text/javascript">
	\$(document).ready(function(){
		var data = "".split(" ");
		\$("#rdists").autocomplete(data);
	});
</script>
<!-- auto-complete -->
		</td>
	</tr>
	<tr class="list">
		<td colspan="1" style="text-align: left;">
<code>
1. 若訂戶已確定取消訂閱，將無法手動加入；
2. 上傳訂戶清單，系統將自動增加，而不會覆蓋原有清單；
3. 清單內重複加入之訂戶系統將自動過濾。
</code>
		</td>
	</tr>
</table>
<br />
<div align="center">
	<a href="admin.cgi?sid=$sid">回上一頁</a>
</div>
EOF
;
    return $result;
}

sub getParams
{
}

sub main
{
    getParams();
    print header(-charset=>'utf-8');
    print templateReplace('index.ht',
                          {'TITLE'    => getDefaultTitle(),
                           'TOPIC'    => getDefaultTopic(),
                           'MENU'     => getAdminMenu($sid),
                           'WIDGET_1' => getWidgetSearch(),
                           'WIDGET_2' => getWidgetSession(),
                           'WIDGET_3' => getNull(),
                           'CONTENT'  => getEditDistContent(),
                          }
                         );
}

main();
