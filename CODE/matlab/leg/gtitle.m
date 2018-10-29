function to=gtitle(s,ext,d,e,a,t,p);
%GTITLE Affiche ou renvoie le titre des graphes
%	GTITLE(S,EXT,D,E,A,T,P) compose un titre en fonction de la chaine S, de 
%	l'extention EXT (G.ext), de la date D, l'�tat E (num), de l'acquisition 
%	A (num), du type r�seau T et de la p�riode d'acquisition P.
%
%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2002
%   Mise � jour : 2005-10-13

sext = {'24h','10j','30j','1an','5an','10a','all','10l'};
snom = {'24 heures','10 jours','30 jours','1 an','5 ans','10 ans','tout','10 derniers �v�nements'};
k = find(strcmp(ext,sext));
if isempty(k)
    nt = '';
else
    nt = sprintf(' (%s)',snom{k});
end
tt = sprintf('{\\bf%s}%s',s,nt);
if nargout == 0
    title(tt,'FontSize',14)
else
    to = {sprintf('{\\fontsize{14} %s} ',tt)};
	if nargin > 2
		to = [to,{sprintf('%s - �tat %03d%% - Acquisition %03d%%',d,round(rmean(e)),round(rmean(a)))}];
	end
	if nargin > 5
	    to{end} = [to{end},sprintf(' - %s - %s',t,p)];
	end
end
