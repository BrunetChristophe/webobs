function S = readop;
%READOP Importe les codes op�rateurs OVSG.
%       READOP renvoie une structure S contenant:
%           - S.code = initiales
%           - S.name = nom complet

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2001-10-20
%   Mise � jour : 2001-10-20

f = 'data/Operateurs_OVSG.txt';
[code,name] = textread(f,'%s%q','commentstyle','shell');
S = struct('code',code,'name',name);
disp(sprintf('Fichier: %s import�.',f))
