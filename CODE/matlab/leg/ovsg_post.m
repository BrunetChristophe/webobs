function ovsg_post(x)
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

url = sprintf('http://%s/sites/etats/feuille_routine.htm',X.RACINE_URL);
pftp = sprintf('%s/Reseaux/Etats',X.RACINE_FTP);
pwww = sprintf('%s/sites/etats',X.RACINE_WEB);
fwww = [pwww '/etats.txt'];
fwhs = [pwww '/etats_hs.htm'];
f1 = sprintf('%s/data/etats.dat',X.RACINE_OUTPUT_MATLAB);
f2 = sprintf('%s/data/etats_st.dat',X.RACINE_OUTPUT_MATLAB);
f3 = sprintf('%s/data/etats_pc.dat',X.RACINE_OUTPUT_MATLAB);
tnow = datevec(now);

% Copie des fichiers d'�tats stations + PC => "etats.txt"
unix(sprintf('cp -fpu %s %s',f1,f2));
unix(sprintf('cat %s %s > %s',f2,f3,fwww));

% Envoi de la routine (tous les lundis � 06h)
if tnow(4) == 6 & tnow(5) < 30 & strcmp(datestr(datenum(tnow),'ddd'),'Mon')
	[s,w] = unix(sprintf('grep -iw "X" %s',fwww));
	if ~isempty(w)
		c = strread(w,'%s','delimiter','\n');
	else
		c = '';
	end
	fid = fopen(fwhs,'wt');
	fprintf(fid,'<html>');
	fprintf(fid,'<b>%s : %d</b> station(s) en panne ou donn�es pas � jour<br>',datestr(now),length(c));
	fprintf(fid,'<blockquote><pre><font face=Courier size=0>');
	for i = 1:length(c)
		fprintf(fid,'%s\n',c{i}(1:44));
	end
	fprintf(fid,'</font></pre></blockquote>D�tails sur la <a href=%s>Feuille de routine</a><br>',url);
	fprintf(fid,'</html>');
	fclose(fid);
	unix(sprintf('mail probleme@soufriere -s ''Bilan pannes r�seau OVSG'' < %s',fwhs));
end

% met � jour un lien symbolique sur le dernier bulletin de l'OVSG
pftp = 'Publis/Bilans';
flst = sprintf('%s/%s/lastbulletin.pdf',X.RACINE_FTP,pftp);
fjpg = sprintf('%s/%s/lastbulletin.jpg',X.RACINE_FTP,pftp);
[w,s] = unix(sprintf('find %s/%s/ -name OVSG_*.pdf',X.RACINE_FTP,pftp));
f = strread(s,'%s','delimiter','\n');
if ~isempty(f)
	% pour �viter les erreurs li�es � l'inexistance des fichiers...
	if ~exist(flst,'file')
		if unix(sprintf('touch %s',flst))
			error(sprintf('WEBOBS: cannot write %s file !',flst));
		end
	end
	% calcul des dates des fichiers
	D0 = dir(f{end});
	D1 = dir(flst);
	if ~strcmp(D0.date,D1.date)
		ff = strread(f{end},'%s','delimiter','/');
		unix(sprintf('ln -s -f %s/%s %s',ff{end-1},ff{end},flst));
		unix(sprintf('%s -scale 71x100 %s %s',X.PRGM_CONVERT,flst,fjpg));
	end
end

