<DecodeHeads>

#<CharsetAliases>
#cp936; gb18030
#cp936; gbk
#cp936; gb2312
#</CharsetAliases>

<CharsetConverters override>
plain;          mhonarc::htmlize;
default;        MHonArc::UTF8::str2sgml;     MHonArc/UTF8.pm
</CharsetConverters>

<TextClipFunc>
MHonArc::UTF8::clip; MHonArc/UTF8.pm
</TextClipFunc>

<MIMEArgs>
m2h_text_html::filter; allownoncidurls
</MIMEArgs>

<!-- ================================================================== -->
<!--  Message Page							-->
<!-- ================================================================== -->
<!--	For message pages, we remove any <html>, et. al. markup
	since they will not be stand-alone documents but included
	by the index page.
  -->

<!-- Disable follow-up/references section.  This is probably a matter
     of personal preference,  If enabled, the FOLUPLITXT and REFSLITXT
     resources will need to be modified to have relative links to
     messages.
  -->
<NoFolRefs>

<MsgPgBegin>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh-tw" lang="zh-tw" dir="ltr">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <link rel="stylesheet" media="all" type="text/css" href="http://net.nthu.edu.tw/2009/lib/exe/css.php?s=all&amp;t=net" />
  <link rel="stylesheet" media="screen" type="text/css" href="http://net.nthu.edu.tw/2009/lib/exe/css.php?t=net" />
  <base target="_blank" />
</head>
<body>
</MsgPgBegin>

<!-- This will be are physical separator for messages. -->
<SubjectHeader>
<h3 class="msg_subject">$SUBJECTNA$</h3>
<hr />
<p class="msg_fields">
<b>Date:</b> $DATE$<br />
<b>From:</b> $FROM$
</p>
</SubjectHeader>

<!-- Only display a very minimal message header.  We already
     rolled a mini-header in SUBJECTHEADER, so we only include
     any additional fields that cannot be referenced via resource
     variables.
     
     We make the style the same as the mini-header above.
  -->
<FieldsBeg>
<p class="msg_fields">
</FieldsBeg>
<LabelBeg>
<b>
</LabelBeg>
<LabelEnd>
:</b>
</LabelEnd>
<FldBeg>

</FldBeg>
<FldEnd>
<br />
</FldEnd>
<FieldsEnd>
</p>
</FieldsEnd>

<FieldOrder>
</FieldOrder>

<HeadBodySep>
<hr />
</HeadBodySep>

<!-- Clear out ending markup. -->
<MsgBodyEnd>

</MsgBodyEnd>
<BotLinks>

</BotLinks>
<MsgPgEnd>
</body>
</html>
</MsgPgEnd>

