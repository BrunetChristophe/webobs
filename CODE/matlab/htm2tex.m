function s=htm2tex(s);
%HTM2TEX HTML to TEX text conversion.
%
%	Author: Francois Beauducel <beauducel@ipgp.fr>
%	Created: 2016-08-12, in Paris (France)

% ---- special characters (to ISO)
s = regexprep(s,'&eacute;','�');
s = regexprep(s,'&Eacute;','�');
s = regexprep(s,'&egrave;','�');
s = regexprep(s,'&Egrave;','�');
s = regexprep(s,'&ecirc;','�');
s = regexprep(s,'&Ecirc;','�');
s = regexprep(s,'&agrave;','�');
s = regexprep(s,'&Agrave;','�');
s = regexprep(s,'&ugrave;','�');
s = regexprep(s,'&Ugrave;','�');
s = regexprep(s,'&ccedil;','�');
s = regexprep(s,'&Ccedil;','�');
s = regexprep(s,'&icirc;','�');
s = regexprep(s,'&Icirc;','�');

% ---- html tags
% subscript
s = regexprep(s,'<sub>(.?)</sub>','_{$1}','ignorecase');
% superscript
s = regexprep(s,'<sup>(.?)</sup>','^{$1}','ignorecase');
% bold
s = regexprep(s,'<b>(.?)</b>','\bf{$1}','ignorecase');
% italic
s = regexprep(s,'<i>(.?)</i>','\it{$1}','ignorecase');
% cleans any other html tags
s = regexprep(s,'<.?>','');
