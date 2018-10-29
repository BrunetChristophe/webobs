function t = datesys2num(s)
%DATESYS2NUM Traduit une date syst�me en date Matlab.
%   Les dates syst�me sont de la forme '27-ao�-2003 10:10:08' pour les OS
%   en Fran�ais et '27-Aug-2003 10:10:08' pour les OS en Anglais.
%
%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2004-04-27
%   Mise � jour : 2004-04-27

mois = {'jan','f�v','mar','avr','mai','jun','jui','ao�','sep','oct','nov','d�c'};
month = {'jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'};

if ~iscell(s)
    s = cellstr(s);
end
sz = length(s);
    
t = zeros(size(s));
for i = 1:sz
    dt = s{i};
    jj = str2num(dt(1:2));
    mm = dt(4:6);
    mm = find(strcmp(lower(mm),mois) | strcmp(lower(mm),month));
    yy = str2num(dt(8:11));
    hh = str2num(dt(13:14));
    nn = str2num(dt(16:17));
    ss = str2num(dt(19:20));
    t(i) = datenum(yy,mm,jj,hh,nn,ss);
end