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
use ListLog;
use ourSession;
use CGI qw(:standard);
use File::Basename;
use Unix::Syslog qw(:macros :subs);
#

my $email    = '';
my $password = '';
my $list     = '';
my $username = '';
my $host     = '';
my $client   = $ENV{'REMOTE_ADDR'} || '查無來源';

# lyshie_20090331: block it first and redirect
sessionIPBlocking();

sub getLoginFormContent
{
    my $accept_hosts = getComboAcceptHosts();
    my @listnames = sort(getListNames());
    my $comboListNames = qq{<select name="list">};

    foreach (@listnames) {
        my %fields = getListFields($_);
        my $desc = $fields{'DESC'};
        if ($fields{'VISI'}) {
            $comboListNames .= qq{<option value="$_">$_ - $desc</option>} . "\n";
        }
        else {
            $comboListNames .= qq{<option value="$_" style="font-style: italic; background-color: gray;">$_ - $desc</option>} . "\n";
        }
    }

    $comboListNames .= qq{</select>};

    my $result = <<EOF
<script type="text/javascript" src="/slist/js/widgets/validtips.js"></script>
<h2>管理者登入</h2>
<br />
<form action="login.cgi" method="post">
<table class="light" border="0" align="center">
<tr>
	<td class="lightheader">電子報名稱：</td>
	<td class="light">$comboListNames</td>
</tr>
<tr>
	<td class="lightheader">管理者信箱：</td>
	<td class="light">
	<input type="text" name="username" size="8" />
	\@$accept_hosts
	</td>
</tr>
<tr>
	<td class="lightheader">密碼：</td>
	<td class="light"><input type="password" name="password" /></td>
</tr>
<tr>
	<td class="lightheader">驗證碼：</td>
	<td class="light">
		<input type="text" id="validtips" name="validate" size="6" maxlength="6" />
		<img src="/slist/cgi-bin/validate.cgi" border="0" align="middle" alt="validate" />
		<br />
		請填入圖上的<span class="alert">數字</span>
                <br />
		<script type="text/javascript">
			function playVoice() {
				var wavURL    = "http://list.net.nthu.edu.tw/slist/cgi-bin/validate_tts.cgi";
				var embedCode = '<embed src=' + wavURL + ' hidden="true" autoplay="true" loop="true" width="1" height="1"></embed>' +
					'<noembed>很抱歉，您的瀏覽器不支援 embed 標籤。</noembed>';
				document.getElementById("playAudio").innerHTML = "";
				document.getElementById("playAudio").innerHTML = embedCode;
			}
			document.write("<a href=\\"javascript:playVoice();\\">語音</a>\\n" +
					"<div id=\\"playAudio\\"></div>\\n");
		</script>
		<noscript>
			<a href="http://list.net.nthu.edu.tw/slist/cgi-bin/validate_tts.cgi">語音</a>
		</noscript>
	</td>
</tr>
<tr>
	<td class="light" colspan="2" style="text-align: center;">
        您現在的連線來源是 <b>$client</b><br />
        <span class="alert">
限本校 IP 登入管理，校外可使用 <a href="http://net.nthu.edu.tw/2009/sslvpn:info" target="_blank">TWAREN SSL-VPN</a>
        </span>
        <br />
        <br />
	<input type="submit" value="登入" />
	</td>
</tr>
</table>
</form>
EOF
;
    return $result;
}

sub getLoginErrorContent
{
    my $result = <<EOF
<h2>管理者登入失敗</h2>
<br />
<code>
登入失敗，請檢查以下原因：
1. 您輸入的電子報名稱不存在或錯誤</li>
2. 您的郵件信箱不接受驗證</li>
3. 您輸入的帳號或密碼錯誤</li>
<a href="login.cgi">按此重新登入</a>！
</code>
</br />
EOF
;

    return $result;
}

sub POP3LoginCheck
{
    # lyshie_20080626: validate the random number
    checkValidate();

    my $pop3 = checkAcceptHosts($email, $password);
    if ($pop3) {
        my $sid = sessionNew($username, $password, $host, $list);

        # lyshie_20080827: do some checks
        return unless($sid);

        openlog(basename($0), LOG_PID, LOG_LOCAL5);
        syslog(LOG_INFO,
               "Login. (listname=%s, maintainer=%s, remote_addr=%s, sid=%s)",
               $list,
               $email,
               $ENV{'REMOTE_ADDR'},
               $sid
              );
        closelog();

        logToList($list,
                  "[%s] LOGIN (%s, %s, %s)",
                  basename($0),
                  $email,
                  $ENV{'REMOTE_ADDR'},
                  $sid
                 );

        print redirect(-uri => "admin.cgi?sid=$sid");
    }
    else {
        print header(-charset=>'utf-8');
        print templateReplace('index.ht',
                              {'TITLE'    => getDefaultTitle(),
                               'TOPIC'    => getDefaultTopic(),
                               'MENU'     => getDefaultMenu(),
                               'WIDGET_1' => getWidgetSearch(),
                               'WIDGET_2' => getNull(),
                               'WIDGET_3' => getNull(),
                               'CONTENT'  => getLoginErrorContent(),
                              }
                             );
    }
}

sub getParams
{
    $username = param('username');
    $host     = param('host');
    $password = param('password');
    $list     = param('list');
    $username = defined($username) ? $username : '';
    $host     = defined($host)     ? $host     : '';
    $password = defined($password) ? $password : '';
    $list     = defined($list)     ? $list     : '';

    if (($username ne '') && ($host ne '')) {
        $email    = "$username\@$host";
    }
}

sub main
{
    getParams();
    if (($email eq '') || ($password eq '') || ($list eq '')) {
        print header(-charset=>'utf-8', -expires => 'now');
        print templateReplace('index.ht',
                              {'TITLE'    => getDefaultTitle(),
                               'TOPIC'    => getDefaultTopic(),
                               'MENU'     => getDefaultMenu(),
                               'WIDGET_1' => getWidgetSearch(),
                               'WIDGET_2' => getNull(),
                               'WIDGET_3' => getNull(),
                               'CONTENT'  => getLoginFormContent(),
                              }
                             );
    }
    else {
        POP3LoginCheck();
    }
}

main();
