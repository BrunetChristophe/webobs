function DOUT=tempflux(mat,tlim,OPT,nograph,dirspec)
%TEMPFLUX Graphes des donn�es de temperatures et flux OVSG (ex forages).
%       TEMPFLUX sans option charge les donn�es les plus r�centes du FTP
%       et retrace tous les graphes pour le WEB.
%
%       TEMPFLUX(MAT,TLIM,JCUM,NOGRAPH) effectue les op�rations suivantes:
%           MAT = 1 (d�faut) utilise la sauvegarde Matlab (+ rapide);
%           MAT = 0 force l'importation de toutes les donn�es anciennes �
%               partir des fichiers FTP et recr�� la sauvegarde Matlab.
%           TLIM = DT ou [T1;T2] trace un graphe sp�cifique ('_xxx') sur 
%               les DT derniers jours, ou entre les dates T1 et T2, au format 
%               vectoriel [YYYY MM DD] ou [YYYY MM DD hh mm ss].
%           TLIM = 'all' trace un graphe de toutes les donn�es ('_all').
%           OPT.fmt = format de date (voir DATETICK).
%           OPT.mks = taille des marqueurs.
%           OPT.cum = p�riode de cumul pour les histogrammes (en jour).
%           OPT.dec = d�cimation des donn�es (en nombre d'�chantillons).
%           NOGRAPH = 1 (optionnel) ne trace pas les graphes.
%
%       DOUT = TEMPFLUX(...) renvoie une structure DOUT contenant toutes les 
%       donn�es :
%           DOUT.code = code 5 caract�res
%           DOUT.time = vecteur temps
%           DOUT.data = matrice de donn�es trait�es (NaN = invalide)
%
%       Sp�cificit�s du traitement pour CDEW:
%           - fichier de mesures manuelles 1968-1994 ('_MAN.TXT') o� -1 = NaN
%           - fichiers journaliers en mV � partir de d�cembre 1994 (.MV)
%           - fichier de calibration (.CLB) pour la convertion en valeurs physique et 
%             le filtrage des donn�es suivant des bornes
%           - affichage temp�rature: �chelle Y = min 3 �C (pour voir le diurne)
%
%       Sp�cificit�s du traitement pour SAVW:
%           - fichier de mesures manuelles 1968-2001 ('_MAN.TXT') o� -1 = NaN
%           - fichiers Campbell journaliers (SAMyyjjj.DAT)
%           - fichiers Nimbus manuels (Nimbus/DD-MM-YY.TXT)
%           - � partir du 23/05/2003 � 20:00 TU, la station est en TU (� cause de la 
%             mise � l'heure automatique depuis acqmtogps)
%           - fichier de calibration (.CLB) pour la convertion en valeurs physique et 
%             le filtrage des donn�es suivant des bornes
%           - d�finition des capteurs et traitements : (c) Jean Vandemeulebrouck
%
%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2001-05-01
%   Mise � jour : 2008-08-30

% ===================== Chargement de toutes les donn�es disponibles

X = readconf;
if nargin < 1, mat = 1; end
if nargin < 2, tlim = []; end
if nargin < 4, nograph = 0; end
if nargin < 5, dirspec = X.MKSPEC_PATH_WEB; end

rcode = 'TEMPFLUX';
timelog(rcode,1);

G = readgr(rcode);
tnow = datevec(G.now);
G.dsp = dirspec;
ST = readst(G.cod,G.obs);
% recuperation des indices par les codes 'DATA' de chaque station
ist = [find(strcmp(ST.dat,'CDEW')),find(strcmp(ST.dat,'SAVW')),find(strcmp(ST.dat,'TASW')),find(strcmp(ST.dat,'GAL'))];

pftp = sprintf('%s/%s',X.RACINE_FTP,G.ftp);
pdon = sprintf('%s/%s',X.RACINE_DATA,G.don);
pwww = X.RACINE_WEB;
cinterv = .7*[1 1 1];

% R�cup�re l'heure du serveur (locale = GMT-4)
tnow = datevec(now);
jnow = floor(datenum(tnow)-datenum(tnow(1),1,0));

 % Importation de toutes les donn?es m?t?o SANNER depuis 2006
if ~nograph
     METEO = meteo(1,[2006,1,1,0,0,0;tnow]);
end
	     

% ===================================================================
% =============== Station GAL
st = ist(4);
scode = lower(ST.cod{st});
alias = ST.ali{st};
sdata = ST.dat{st};
sname = ST.nom{st};
stitre = sprintf('%s : %s',alias,sname);
stype = 'T';

% Initialisation des variables
samp = 1/1440; % pas d'�chantillonnage des donn�es (en jour)
last = 2/24;    % d�lai d'estimation pour l'�tat de la station (en jour)

G.cpr = 'OVSG-IPGP';

t = [];
d = [];

% Ann�e et jour de d�but des donn�es t�l�m�tr�es
ydeb = 2006;
jdeb = 299;

% Test: chargement si la sauvegarde Matlab existe
f_save = sprintf('%s/past/%s_past.mat',X.RACINE_OUTPUT_MATLAB,scode);
if mat & exist(f_save,'file')
    load(f_save,'t','d');
    disp(sprintf('File: %s imported.',f_save))
    tdeb = datevec(t(end));
    ydeb = tdeb(1);
    jdeb = floor(t(end)-datenum(ydeb,1,0))+1;
    if ydeb==tnow(1) & jdeb==jnow
        flag = 1;
    else
        flag = 0;
    end
else
    disp('No temporary data backup or rebuild forced (MAT=0). Loading all available data...');
    flag = 0;
end

% Chargement des fichiers journaliers (*.dat)
for annee = ydeb:tnow(1)
    p = sprintf('%s/%s/%d',pftp,sdata,annee);
    if exist(p,'dir')
        if annee==ydeb, jj = jdeb; else jj = 1; end
        for j = jj:366
            % Sauvegarde Matlab des donn�es "anciennes"
            if ~flag & annee==tnow(1) & j==jnow
                save(f_save);
                disp(sprintf('File: %s created.',f_save))
            end
            f = sprintf('%s/%s%02d%03d.dat',p,sdata,mod(annee,100),j);
            if exist(f,'file')
                [dd] = textread(f,'%q','delimiter',',','bufsize',8191);
                if ~isempty(dd)
			if size(dd)/18 ~= floor(size(dd)/18)
				disp(sprintf('** Warning: file %s has not 18 columns. Not imported.',f))
			else
				dd = reshape(dd,[18,size(dd,1)/18])';
                    		t = [t;isodatenum(dd(:,1))];
                    		d = [d;str2double(dd(:,3:end))];
                    		disp(sprintf('File: %s imported.',f))
			end
                end
            end
        end
    end
end    

% Passage en heure locale
t = t + G.utc/24;
    
% Calibration et filtres
[d,C] = calib(t,d,ST.clb(st));
nx = ST.clb(st).nx;

% Definition des voies affichees
so = [1,3,5,7,9,10,11,12,13,16];

tn = min(t);
tm = datenum(tnow);
tlast(1) = t(end);

% D�codage de l'argument TLIM
if isempty(tlim)
    ivg = 1:(length(G.ext)-2);
end
if ~isempty(tlim) & strcmp(tlim,'all')
    ivg = length(G.ext)-1;
    G.lim{ivg}(1) = min(t);
end
if ~isempty(tlim) & ~ischar(tlim)
    if size(tlim,1) == 2
        t1 = datenum(tlim(1,:));
        t2 = datenum(tlim(2,:));
    else
        t2 = datenum(tnow);
        t1 = t2 - tlim;
    end
    ivg = length(G.ext);
    G.lim{ivg} = minmax([t1 t2]);
    dtemps = abs(diff([t1 t2]));
    if nargin > 2
        G.fmt{ivg} = OPT.fmt;
        G.mks{ivg} = OPT.mks;
        G.cum{ivg} = OPT.cum;
        G.dec{ivg} = OPT.dec;
    else
        G.dec{ivg} = 1;
        if dtemps > 15, G.dec{ivg} = 60; end
        if dtemps > 180, G.dec{ivg} = 1440; end
        OPT.exp = 1;
    end
    if ~nograph & OPT.exp
        f = sprintf('%s/%s/%s_xxx.txt',X.RACINE_WEB,dirspec,scode);
        k = find(t>=G.lim{ivg}(1) & t<=G.lim{ivg}(2));
        tt = datevec(t(k));
        fid = fopen(f,'wt');
        fprintf(fid, '# DATE: %s\r\n', datestr(now));
        fprintf(fid, '# TITL: %s\r\n',stitre);
        fprintf(fid, '# SAMP: %d\r\n',samp*86400);
        fprintf(fid, '# CHAN: YYYY MM DD HH NN');
        fmt = '%4d-%02d-%02d %02d:%02d:%02.0f';
        for i = 1:nx
            fprintf(fid, ' %s_(%s)',C.nm{i},C.un{i});
            fmt = [fmt ' %0.2f'];
        end
        fprintf(fid,'\r\n');
        fmt = [fmt '\r\n'];
        fprintf(fid,fmt,[tt(:,1:6),d(k,:)]');
        fclose(fid);
        disp(sprintf('File: %s created.',f))
    end
end

% Renvoi des donn�es dans DOUT, sur la p�riode de temps G(end).lim
if nargout > 0
    k = find(t>=G.lim{end}(1) & t<=G.lim{end}(2));
    DOUT(1).code = scode;
    DOUT(1).time = t(k);
    DOUT(1).data = d(k,:);
    DOUT(1).chan = C.nm;
    DOUT(1).unit = C.un;
end

% Si nograph==1, quitte la routine sans production de graphes
if nograph == 1, ivg = []; end

% ----------------------- Trac� des graphes

for ig = ivg

    figure(1), orient tall, clf
    k = find(t>=G.lim{ig}(1) & t<=G.lim{ig}(2));

    if G.dec{ig} == 1
        tk = t(k);
        dk = d(k,:);
    else
	disp(sprintf('Decimation: original data are resampled by a factor of %d ...',G.dec{ig}));
        tk = rdecim(t(k),G.dec{ig});
        dk = rdecim(d(k,:),G.dec{ig});
    end

    % Etat de la station
    acqui = round(100*length(find(t>=G.lim{ig}(1) & t<=G.lim{ig}(2)))*samp/diff(G.lim{ig}));
    ke = find(t >= G.lim{ig}(2)-last);
    if ~isempty(ke)
      etat = 0;
        for i = 1:length(so)
            if ~isempty(find(~isnan(d(ke,so(i)))))
                etat = etat+1;
            end
        end
        etat = 100*etat/length(so);
    else
        etat = 0;
    end
    
    % Titre et informations
    G.tit = gtitle(stitre,G.ext{ig});
    G.eta = [G.lim{ig}(2),etat,acqui];
	
    if ig == 1
        etats(1) = etat;
        acquis(1) = acqui;
	sd = [];
	for i = 1:nx
        	sd = [sd,sprintf('%0.2f %s, ', d(end,i),C.un{i})];
	end
        mketat(etat,tlast(1),sd,scode,G.utc,acqui)
    end
    
    if ~isempty(k)
	    G.inf = {'Derni�re mesure:', ...
		        sprintf('{\\bf%s} {\\it%+d}',datestr(t(k(end))),G.utc), ...
				'(min|moy|max)',' '};
	    for i = 1:length(so)
	        G.inf = [G.inf,{sprintf('%d. %s = {\\bf%1.2f %s} (%1.1f|%1.1f|%1.1f)', ...
			so(i),C.nm{so(i)},d(k(end),so(i)),C.un{so(i)},rmin(d(k,so(i))),rmean(d(k,so(i))),rmax(d(k,so(i))))}];
	    end
	else
	    G.inf = {''};
    end
	
    % Temperatures: eau, cond (F2 et avg)
    subplot(7,1,1:2), extaxes
    plot(tk,dk(:,so(2)),'.b','Markersize',G.mks{ig})
    hold on
    plot(tk,dk(:,so(3)),'.r','Markersize',G.mks{ig})
    plot(tk,dk(:,so(8)),'.','Color',[0,.7,0],'Markersize',G.mks{ig})
    plot(tk,dk(:,so(9)),'.m','Markersize',G.mks{ig})
    hold off
    set(gca,'XLim',G.lim{ig},'FontSize',8)
    datetick2('x',G.fmt{ig},'keeplimits')
    ylabel(sprintf('Temp�ratures (%s)',C.un{so(2)}))
    if G.dec{ig} ~= 1
        title(sprintf('Moyenne %s',adjtemps(samp*G.dec{ig})),'HorizontalAlignment','center','FontSize',8)
    end
    h = legend(C.nm{so(2)},C.nm{so(3)},C.nm{so(8)},C.nm{so(9)},0);

    % Temperature air (F2 et avg))
    subplot(7,1,3), extaxes
    plot(tk,dk(:,so(4)),'.b','Markersize',G.mks{ig})
    hold on
    plot(tk,dk(:,so(5)),'.r','Markersize',G.mks{ig})
    hold off
    set(gca,'XLim',G.lim{ig},'FontSize',8)
    datetick2('x',G.fmt{ig},'keeplimits')
    ylim = get(gca,'YLim');
    ylabel(sprintf('Temp. air (%s)',C.un{so(4)}))
    h = legend(C.nm{so(4)},C.nm{so(5)},0);

    % Conductivité(2 sondes ?)
    subplot(7,1,4), extaxes
    plot(tk,dk(:,so(6)),'.b',tk,dk(:,so(7)),'.r','Markersize',G.mks{ig})
    set(gca,'XLim',G.lim{ig},'FontSize',8)
    datetick2('x',G.fmt{ig},'keeplimits')
    ylim = get(gca,'YLim');
    ylabel(sprintf('Conductivite (%s)',C.un{so(6)}))
    h = legend(C.nm{so(6)},C.nm{so(7)},0);

    % Debit
    subplot(7,1,5), extaxes
    plot(tk,dk(:,so(10)),'.b','Markersize',G.mks{ig})
    set(gca,'XLim',G.lim{ig},'FontSize',8)
    datetick2('x',G.fmt{ig},'keeplimits')
    ylim = get(gca,'YLim');
    ylabel(sprintf('%s (%s)',C.nm{so(10)},C.un{so(10)}))

    % Tension batterie
    subplot(7,1,6), extaxes
    plot(tk,dk(:,so(1)),'.m','Markersize',G.mks{ig})
    set(gca,'XLim',G.lim{ig},'FontSize',8)
    ylim = get(gca,'YLim');
    datetick2('x',G.fmt{ig},'keeplimits')
    ylabel(sprintf('%s (%s)',C.nm{so(1)},C.un{so(1)}))

    % Pluie SANNER (histogrammes glissants horaire / diurne / mensuel)
    subplot(7,1,7), extaxes
    kimp = find(METEO(2).time>=G.lim{ig}(1) & METEO(2).time<=G.lim{ig}(2));
    dtemps = diff(G.lim{ig});
    if dtemps < 100
    	area(METEO(2).time(kimp),METEO(2).data(kimp,[10,11]))
    	h = legend('Hist. glissant horaire (mm/h)','Hist. glissant diurne (mm/j)',0);
    else
    	area(METEO(2).time(kimp),METEO(2).data(kimp,[11,12]))
    	h = legend('Hist. glissant diurne (mm/j)','Hist. glissant mensuel (mm/30j)',0);
    end
    colormap([0,1,0;0,1,1])
    set(h,'FontSize',8)
    set(gca,'XLim',G.lim{ig},'FontSize',8)
    datetick2('x',G.fmt{ig},'keeplimits')
    ylabel(sprintf('Pluie SANNER (mm)'))
							
    tlabel(G.lim{ig},G.utc)

    mkgraph(sprintf('%s_%s',scode,G.ext{ig}),G)
end
close



timelog(rcode,2)
