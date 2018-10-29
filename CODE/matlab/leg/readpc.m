function A = readpc;
%READPC Importe les caract�ristiques des PC d'acquisition OVSG.
%       READPC lit le fichier "data/PC_Acqui_OVSG.txt" et renvoie une 
%       structure A contenant:
%           - A.pc = nom du PC
%           - A.npc = machine correspondante

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2003-07-01
%   Mise � jour : 2004-04-27

X = readconf;
f = sprintf('%s/%s',X.RACINE_FICHIERS_CONFIGURATION,X.FILE_PC_ACQUI);
[ac,pc] = textread(f,'%s%s','commentstyle','shell');
A.ac = ac;
A.pc = pc;
disp(sprintf('Fichier: %s import�.',f))
