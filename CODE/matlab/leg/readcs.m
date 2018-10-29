function C = readcs;
%READCS Importe les codes de s�ismes
%       READCS renvoie une cellule C contenant:
%           - C(1,:) = code type de s�isme (2 lettres)
%           - C(2,:) = nom complet
%           - C(3,:) = nom abr�g� (communiqu�s)

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2002-01-04
%   Mise � jour : 2009-10-07

X = readconf;

f = sprintf('%s/codes_seismes.txt',X.RACINE_FICHIERS_CONFIGURATION);
[cde,nom,abr] = textread(f,'%q%q%q','commentstyle','shell');
C = [cde';nom';abr'];
disp(sprintf('File: %s imported.',f))
