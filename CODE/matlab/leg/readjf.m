function J = readjf(annee);
%READJF Importe les jours f�ri�s Guadeloupe pour l'ann�e en cours
%       READJF renvoie une structure J contenant:
%           - J.dte = date (format Matlab)
%           - J.nom = nom du jour f�ri�
%
%	READJF(A) renvoie les jours f�ri�s pour l'ann�e A

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2002-12-26
%   Mise � jour : 2010-06-08

X = readconf;

if nargin < 1
	today = datevec(now);
	annee = today(1);	% ann�e en cours
end

f = sprintf('%s/%s',X.RACINE_FICHIERS_CONFIGURATION,X.FERIES_FILE);
[dte,nom] = textread(f,'%q%q','delimiter','|','commentstyle','shell');

% Calcul du jour de P�ques $PQ de l'ann�e en cours
% par l'algorithme de Oudin, valide � partir de l'ann�e 1583 (d'apr�s Wikip�dia)
G = mod(annee,19);												% nombre d'or diminu� de 1
C = floor(annee/100);
C_4 = floor(C/4);
H = mod(19 * G + C - C_4 - floor((8*C + 13)/25) + 15,30);
K = floor(H/28);
I = (K*floor(29/(H + 1))*floor((21 - G)/11) - 1)*K + H;				% nombre de jours entre la pleine lune pascale et le 21 mars
R = 28 + I - mod(floor(annee/4) + annee + I + 2 + C_4 - C,7);	% date du mois mars
[w,PQ] = unix(sprintf('date -I -d "%04d-03-%02d"',annee,R));		% date du dimanche de P�ques !!

for i = 1:length(dte)
	dte{i} = strrep(dte{i},'$Y',sprintf('%04d',annee));
	if ~isempty(findstr(dte{i},'$PQ'))
		dte{i} = [dte{i},' days'];
	end
	dte{i} = strrep(dte{i},'$PQ',PQ);
	[w,s] = unix(sprintf('date -I -d "%s"',dte{i}));
	J.dte(i) = datenum(str2double(s(1:4)),str2double(s(6:7)),str2double(s(9:10)));
end
J.nom = nom;
disp(sprintf('Fichier: %s import�.',f))
