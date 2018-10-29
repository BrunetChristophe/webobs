function mkspec
%MKSPEC Interpr�te le formulaire de graphes sp�cifiques.
%   MKSPEC est lanc� par crontab toutes les minutes d�s qu'un fichier visu_grspec.tmp
%   est d�tect� (voir "matlab-spec.csh").
%
%   - lance successibement toutes les routines choisies avec les options (dates et autre)
%   - les graphes (et donn�es export�es) sont plac�es dans le r�pertoire
%   - un .tgz du tout est produit au m�me endroit
%   - un fichier index.htm pr�sente l'ensemble sous forme de page web
%   - un email est envoy� au demandeur
%
%   Sp�cificit�s:
%   	- le fichier contenant les param�tres de requ�te n'a pas de format fixe (les champs d�pendent
%         des routines s�lectionn�es); il faut d�coder la ligne d'en-t�te.
%	- le fichier peut contenir plusieurs requ�tes; elles sont donc trait�es s�quentiellement.
%
%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2002-01-11
%   Mise � jour : 2013-10-24

X = readconf;

rcode = 'MKSPEC';
pwww = X.RACINE_WEB;
phtm = X.MKSPEC_RESULT_PATH_WEB;
fdat = sprintf('%s/%s',X.RACINE_OUTPUT_TOOLS,X.MKSPEC_OUTPUT_TMP_FILE);
fhcs = sprintf('%s/%s',X.RACINE_DATA_MATLAB,X.MKSPEC_FILE_SISMOHYP);
flog = 'visu_grspec.log';

if ~exist(fdat,'file')
	return;
end

% Archivage des requetes
unix(sprintf('cat %s >> %s/%s/%s',fdat,pwww,phtm,flog));

% lecture du fichier de requ�te
[line] = textread(fdat,'%s','delimiter','\n');
disp(sprintf('File: %s imported.',fdat));

if isempty(line)
	return
end

for ii = 1:length(line)/2

	[head] = strread(line{ii*2-1},'%q','delimiter','|');
	[data] = strread(line{ii*2},'%q','delimiter','|');

	% intervalle de temps (10 premiers champs: Y1 B1 D1 H1 M1 Y2 B2 D2 H2 M2)
	dd = str2double(data(1:10));
	t1 = datenum([dd(1:5);0]');
	t2 = datenum([dd(6:10);0]');
	
	% le reste de la ligne [data] est interpr�t�e en fonction des champs pr�sents dans [head] 
	sname = data{find(strcmp(head,'remHost'))};
	suser = data{find(strcmp(head,'remUser'))};

	OPT.ico = 1;
	OPT.ppi = str2double(data(find(strcmp(head,'PPI'))));
	OPT.tu = str2double(data(find(strcmp(head,'TU'))));
	OPT.fmt = str2double(data(find(strcmp(head,'FMT'))));
	OPT.mks = str2double(data(find(strcmp(head,'MKS'))));
	OPT.cum = eval(data{find(strcmp(head,'CUM'))});
	OPT.dec = str2double(data(find(strcmp(head,'DEC'))));
	k = find(strcmp(head,'EPS'));
	if ~isempty(k)
		OPT.eps = str2double(data(k));
	else
		OPT.eps = 0;
	end
	k = find(strcmp(head,'EXP'));
	if ~isempty(k)
		OPT.exp = str2double(data(k));
	else
		OPT.exp = 0;
	end
	% magnitudes
	hm = str2double(data(find(strcmp(head,'HMmax') | strcmp(head,'HMmin'))));
	OPT.hmmx = max(hm);
	OPT.hmmn = min(hm);
	% profondeurs
	hp = str2double(data(find(strcmp(head,'HPmax') | strcmp(head,'HPmin'))));
	OPT.hpmx = max(hp);
	OPT.hpmn = min(hp);
	% s�lection type de s�ismes
	OPT.htyp = split(data{find(strcmp(head,'HTyp'))},'+');
	% filtre intensit�s MSK
	OPT.hmsk = str2double(data(find(strcmp(head,'MSK'))));
	% filtre classe
	OPT.hqm = data{find(strcmp(head,'HQM'))};
	% filtre Gap
	OPT.hgap = str2double(data(find(strcmp(head,'HGap'))));
	% filtre RMS
	OPT.hrms = str2double(data(find(strcmp(head,'HRMS'))));
	% filtre erreur horizontale
	OPT.herh = str2double(data(find(strcmp(head,'HErh'))));
	% filtre erreur verticale
	OPT.herz = str2double(data(find(strcmp(head,'HErz'))));
	% appliquer les filtres
	if ~isempty(find(strcmp(head,'HFiltre')))
		OPT.hfil = 1;
	else
		OPT.hfil = 0;
	end
	% afficher tous les s�ismes en arri�re plan
	if ~isempty(find(strcmp(head,'HAnciens')))
		OPT.hanc = 1;
	else
		OPT.hanc = 0;
	end
	% afficher les stations
	if ~isempty(find(strcmp(head,'HStations')))
		OPT.hsta = 1;
	else
		OPT.hsta = 0;
	end
	% param�tres carte sp�cifique
	OPT.htit = data{find(strcmp(head,'HTitre'))};
	hlo = str2double(data(find(strcmp(head,'Lon1') | strcmp(head,'Lon2'))));
	OPT.hloe = max(hlo);
	OPT.hloo = min(hlo);
	hla = str2double(data(find(strcmp(head,'Lat1') | strcmp(head,'Lat2'))));
	OPT.hlas = min(hla);
	OPT.hlan = max(hla);
	OPT.hcaz = str2double(data(find(strcmp(head,'HAz'))));
	OPT.hcpr = str2double(data(find(strcmp(head,'HProf'))));
	% modification de la carte sp�cifique en routine
	k = find(strcmp(head,'HCS'));
	if ~isempty(k)
		OPT.hcsp = str2double(data(k));
	else
		OPT.hcsp = 0;
	end
	% d�tecte les routines
	vr = strmatch('routine_',head);
	if length(vr)

		% charge la liste des op�rateurs
		O = readus;
		kuser = find(strcmp(suser,O.usr));
		if ~isempty(kuser)
			nuser = O.nom{kuser};
		else
			nuser = 'inconnu';
		end
    
		% construction du r�pertoire de requete
		tnow = round(datevec(now));
		sdate = sprintf('%d%02d%02d_%02d%02d%02d',tnow);
		dnam = sprintf('%s/%s_%s_%s',phtm,sdate,sname,suser);
		dirspec = sprintf('%s/%s',pwww,dnam);
		unix(sprintf('mkdir %s',dirspec));
		disp(sprintf('R�pertoire: %s cr��.',dirspec));

		% copie les param�tres de requ�te
		f = sprintf('%s/param.txt',dirspec);
		fid = fopen(f,'wt');
		for i = 1:length(head)
			fprintf(fid,'%s|%s\n',head{i},data{i});
		end
		disp(sprintf('File: %s created.',f));

		% lancement des routines
		re = '';
		for i = 1:length(vr)
			nr = lower(head{vr(i)}(9:end));
			re = sprintf('%s %s',re,upper(nr));
			disp(sprintf('%s: lauch the routine "%s"...',rcode,nr));
			if exist(nr)
				G = readgr(nr)			% r�cup�re les infos de la routine
				dt = (G.utc - OPT.tu)/24;	% calcule le d�calage de dates suivant la demande et le temps r�seau
				nrout = sprintf('%s(1,[%d %d %d %d %d %d;%d %d %d %d %d %d],OPT,0,''%s'')',nr,datevec(t1+dt),datevec(t2+dt),dnam);
				ncatc = sprintf('disperr(''%s'')',nr);
				disp(sprintf('Eval: %s',nrout))
				eval(nrout,ncatc);
			end
		end
    
		if ~isempty(lasterr)
			fid = fopen(sprintf('%s/error.txt',dirspec),'wt');
			fprintf(fid,'%s',lasterr);
			fclose(fid);
		end

		% identification des images cr��es
		ftgz = sprintf('%s_OVSG_request.tgz',sdate);
		LI = dir(sprintf('%s/*.png',dirspec));
		fimg = cellstr(char(LI.name));
		nb = length(LI);
		fgra = [];
		snav = ' ';
		for i = 1:nb
			ss = strread(fimg{i},'%s',1,'delimiter','_');
			fgra = [fgra,ss];
			snav = [snav sprintf('<A href="#%s"><B>%s</B></A> |',ss{:},upper(ss{:}))];
		end
		snav(end) = [];

		% fabrication d'une page Web sur la requete
		stitre = 'R�sultat de Requ�te Graphique';
		fhtm = [dirspec '/index.htm'];
		matp = sprintf('<I>mkspec.m</I> (c) FB, OVSG-IPGP, %d-%02d-%02d %02d:%02d:%02d',tnow);
		bk = '&nbsp;';

		fid = fopen(fhtm,'wt');

		fprintf(fid,'<HTML><HEAD><TITLE>%s %s</TITLE><LINK rel="stylesheet" type="text/css" href="/%s"></HEAD>\n',stitre,datestr(now,'dd-mmm-yyyy'),X.FILE_CSS);
		fprintf(fid,'<BODY>\n');
		fprintf(fid,'<FORM>\n');
		fprintf(fid,'<TABLE border="0" width="100%%"><TR>');
		fprintf(fid,'<TD width="165"><A href="/" target="_top"><IMG src="/images/logo_ovsg.gif" alt="Accueil" border="0"></A></TD>');
		fprintf(fid,'<TD><H1>%s</H1>\n',stitre);
		fprintf(fid,'<P>Date: <B>%s</B><BR>\n',datestr(datenum(tnow)));
		fprintf(fid,'Utilisateur: <B>%s</B> (%s)<BR>\n',suser,nuser);
		fprintf(fid,'Machine: <B>%s</B><BR>',sname);
		fprintf(fid,'P�riode demand�e: <B>%s</B> � <B>%s</B> (<I>UTC %+d</I>)<BR>',datestr(t1),datestr(t2),OPT.tu);
		fprintf(fid,'Routine(s) ex�cut�e(s): <B>%s</B><BR>',re);
		fprintf(fid,'Nombre de graphe(s) cr��(s): <B>%d</B></FONT></P>\n',length(fimg));
		fprintf(fid,'<P>[ <A href="../">Retour</A> | <A href="%s">Archive data (.TGZ)</A> ]</FONT></P>\n',ftgz);
		fprintf(fid,'</TD></TR></TABLE>');

		if ~isempty(lasterr)
			fprintf(fid,'<H2>Erreur d''ex�cution Matlab...</H2><PRE>%s</PRE>',lasterr);
		end
		for i = 1:nb
			fprintf(fid,'<P><A name="%s"></A>[%s]<BR>\n',fgra{i},snav);
			if findstr(fgra{i},'SISMOHYP')
				fprintf(fid,'<A href="%s_xxx.htm"><IMG src="%s" alt="Cliquez pour acc�der � la carte int�ractive"></A></P>\n',fgra{i},fimg{i});
			else
				fprintf(fid,'<IMG src="%s"></P>\n',fimg{i});
			end
			fprintf(fid,'<P align="right"><A href="#top"><B>Retour en haut</B></A></P>');
		end

		fprintf(fid,'<BR><TABLE><TR><TD><IMG src="/images/matpad.gif" width="26" height="26"></TD>');
		fprintf(fid,'<TD>%s</TD></TR></TABLE>\n',matp);
		fprintf(fid,'</FORM></BODY></HTML>\n');

		fclose(fid);
		disp(sprintf('Fichier: %s cr��.',fhtm))

		% Cr�ation du ZIP contenant tous les fichiers
		unix(sprintf('tar zcf %s/%s %s/*',dirspec,ftgz,dirspec));
		disp(sprintf('Fichier: %s/%s cr��.',dirspec,ftgz));


		% Envoi d'un email � l'utilisateur
		if ~isempty(O.mel(kuser))
			ftmp = sprintf('%s/mail.txt',dirspec);
			fid = fopen(ftmp,'wt');
			fprintf(fid,'%s\n',stitre);
			fprintf(fid,'Date: %s\n',datestr(datenum(tnow)));
			fprintf(fid,'Utilisateur: %s (%s)\n',suser,nuser);
			fprintf(fid,'Machine: %s\n',sname);
			fprintf(fid,'P�riode demand�e: %s � %s (UTC %+d)\n',datestr(t1),datestr(t2),OPT.tu);
			fprintf(fid,'Routine(s) ex�cut�e(s): %s\n',re);
			if ~isempty(lasterr)
				fprintf(fid,'\n\n***** Erreur d''ex�cution Matlab *****\n\n%s\n***** D�sol�, r�essayez plus tard...\n\n',lasterr);
			end
			fprintf(fid,'\nCliquer sur le lien ci-dessous pour acc�der au(x) graphe(s) et fichier(s):\n\n');
			fprintf(fid,'http://%s/%s/',X.RACINE_URL,dnam);
			fclose(fid);
			alerte(sprintf('[WEBOBS-%s] Your graphic request is ready',X.OBSERVATOIRE),O.mel{kuser},ftmp);
		end
	end
end

%==========================================================================
% Affiche des informations sur l'erreur
function disperr(s)
disp(sprintf('* WEBOBS: Problem with Matlab function %s',upper(s)));
disp(lasterr);

