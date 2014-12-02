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
