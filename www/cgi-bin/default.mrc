<DecodeHeads>

<CharsetAliases>
cp936; gb18030
cp936; gbk
cp936; gb2312
</CharsetAliases>

<CharsetConverters override>
plain;          mhonarc::htmlize;
default;        MHonArc::UTF8::str2sgml;     MHonArc/UTF8.pm
</CharsetConverters>

<TextClipFunc>
MHonArc::UTF8::clip; MHonArc/UTF8.pm
</TextClipFunc>

<MIMEFilters>
application/ms-tnef;  m2h_tnef::filter;	/usr/local/slist/www/cgi-bin/mhtnef.pl
</MIMEFilters>

<MIMEARGS>
m2h_text_html::filter; allownoncidurls
</MIMEARGS>

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

</MsgPgEnd>

