
function ovsg_pre(x)
%OVSG   Routines des r�seaux OVSG
%       OVSG sans argument lance l'ensemble des routines de r�seaux pour cr�ation
%       des graphes courants et de l'�tat des r�seaux (routine automatique).
%
%       OVSG('all') lance uniquement les graphes de toutes les donn�es.
%
%       Particularit�s:
%           - les scripts de traitement sont lanc�s avec la fonction EVAL, ce qui permet
%             de poursuivre la routine en cas d'erreur sur l'un des scripts.
%           - les deux fichiers d'�tat (stations et PC) sont merg�s en fin de routines
%             pour produire le fichier d'�tat unique utilis� pour la feuille de routine.
%           - tous les lundis � 6h, un mail est envoy� � ovsg@ovsg.univ-ag.fr pour dresser
%             un bilan des pannes.

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2001-06-06
%   Mise � jour : 2007-02-15

X = readconf;
R = readgr;

pwww = sprintf('%s/sites/etats',X.RACINE_WEB);
fwww = [pwww '/etats.txt'];
fwhs = [pwww '/etats_hs.htm'];
f1 = sprintf('%s/data/etats.dat',X.RACINE_OUTPUT_MATLAB);
tnow = datevec(now);
snow = sprintf('%4d-%02d-%02d %02d:%02d:%02.0f',tnow);

fid = fopen(f1,'wt');
fprintf(fid,'#--------------------------------------------------------\n');
fprintf(fid,'# ROUTINE OVSG: �tat automatique des stations\n');
fprintf(fid,'# %s (locales)\n#\n',datestr(now));
fprintf(fid,'#Pb  Station   E%%  A%% Date       Heure    TU Derni�res donn�es \n');
fprintf(fid,'#------------|---|---|----------|--------|--|------------------\n');
fprintf(fid,'-     ROUTINE 100 100 %s -4 1\n',snow);
fclose(fid);
