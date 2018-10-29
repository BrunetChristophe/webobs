function DOUT = bojap(mat,tlim,OPT,nograph,dirspec)
%BOJAP  Traitement des donn�es des Boites Japonaises
%       BOJAP sans option charge les donn�es les plus r�centes du FTP
%       et retrace tous les graphes pour le WEB.
%
%       BOJAP(MAT,TLIM,OPT,NOGRAPH) effectue les op�rations suivantes:
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
%       DOUT = BOJAP(...) renvoie une structure DOUT contenant toutes les 
%       donn�es des stations concern�es i:
%           DOUT(i).code = code 5 caract�res
%           DOUT(i).time = vecteur temps
%           DOUT(i).data = matrice de donn�es trait�es (NaN = invalide)
%
%       Sp�cificit�s du traitement:
%           - 1 seul fichier de donn�es ASCII ('bojap_dat.txt')
%           - uniques matrices t (temps) et d (donn�es): les sites sont s�lectionn�s 
%             par un find dans la matrice si (site)
%           - utilise le fichier de noms et positions des stations OVSG (avec 'J')
%           - tri chronologique et �limination des donn�es redondantes (correction de saisie)
%           - pas de sauvegarde Matlab
%           - exportation de fichiers de donn�es "trait�es" par site sur le FTP
%
%   Auteurs: F. Beauducel + G. Hammouya, OVSG-IPGP
%   Cr�ation : 2003-06-12
%   Mise � jour : 2009-10-06

% ===================== Chargement de toutes les donn�es disponibles

X = readconf;
if nargin < 1, mat = 1; end
if nargin < 2, tlim = []; end
if nargin < 3, OPT = 0; end
if nargin < 4, nograph = 0; end
if nargin < 5, dirspec = X.MKSPEC_PATH_WEB; end

rcode = 'BOJAP';
timelog(rcode,1)

G = readgr(rcode);
tnow = datevec(G.now);
G.dsp = dirspec;
ST = readst(G.cod,G.obs);
pdat = sprintf('/cgi-bin/%s?unite=mmol&site=',X.CGI_AFFICHE_BOJAP);
G.dat = {sprintf('%s%s%s',pdat,G.obs,G.cod)};


% types d'�chantillonnage et marqueurs associ�s (voir fonction PLOTMARK)
tmkt = {'.','v'};
tmks = 3;
sveille = [];

% ==== Initialisation des variables
samp = 30;     % pas d'�chantillonnage des donn�es (en jour)
last = 45;     % d�lai d'estimation pour l'�tat de la station (en jour)
stype = 'M';

sname = G.nom;
G.cpr = 'OVSG-IPGP';
%pftp = '../../G�ochimie/JapBox';
pftp = sprintf('%s/%s',X.RACINE_FTP,G.ftp);

% Constantes
vkoh = 535;         			% volume de la solution KOH (cm3)
mkoh = str2double(X.GMOL_KOH);
mcl = str2double(X.GMOL_Cl);    % masse molaire Cl (g/mol)
mso4 = str2double(X.GMOL_SO4);      % masse molaire SO4 (g/mol)
mco2 = str2double(X.GMOL_CO2);	  % masse molaire CO2 (g/mol)
cco2 = 12/44;       % rapport esp�ces C / CO2
sso4 = 32/96;       % rapport esp�ces S / SO4

% ==== Importation des param�tres stations
i0 = find(strcmp(ST.ali,'MTO'));   % indice de la station "blanc"

% ==== Importation du fichier de donn�es (cr�� par le formulaire WEB)
f = sprintf('%s/%s.DAT',pftp,rcode);
[id,d1,h1,d2,h2,si,cl,co2,so4,m1,m2,m3,m4,h2o,koh,co]=textread(f,'%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%*[^\n]','delimiter','|','headerlines',1);
disp(sprintf('Fichier: %s import�.',f))

x = char(d2);
t = datenum(str2double([cellstr(x(:,1:4)) cellstr(x(:,6:7)) cellstr(x(:,9:10))]));
x = char(d1);
t0 = datenum(str2double([cellstr(x(:,1:4)) cellstr(x(:,6:7)) cellstr(x(:,9:10))]));
z0 = zeros([size(x,1) 1]);

% Remplit la matrice de donn�es avec :
%   1 = dur�e mesure (j)
%   2 = concentration Chlorures (mmol/l/j)
%   3 = concentration Carbonates (mmol/l/j)
%   4 = concentration Sulfates (mmol/l/j)
%   5 = masse totale (g)
%   6 = masse H2O (g)
%   7 = masse KOH (g)
%   8 = volume total (cm3) = approximation ~= masse d'eau r�colt�e
%   9 = rapport S/Cl
%   10 = rapport S/C
%   11 = flux Chlore (g/j)
%   12 = flux Carbone (g/j)
%   13 = flux Soufre (g/j)
%   14 = flux eau condens�e (g/j)

dd = str2double([m1,m2,m3,m4]);
d = [t-t0,str2double([cl,co2,so4]),NaN*z0,str2double([h2o,koh]),NaN*[z0,z0,z0]];
d(:,2) = (d(:,2)/mcl)./d(:,1);
d(:,3) = (d(:,3)/mco2)./d(:,1);
d(:,4) = (d(:,4)/mso4)./d(:,1);
d(:,5) = rsum(dd')';
d(:,7) = mkoh*d(:,7).*d(:,6)/1e3;
%d(:,8) = d(:,5) - d(:,7) - d(:,6) + vkoh;
d(:,8) = d(:,5) - d(:,7) - d(:,6);
d(:,9) = d(:,4)./d(:,2);
d(:,10) = d(:,4)./d(:,3);
d(:,11) = mcl*d(:,2).*d(:,8)/1e6;
d(:,12) = cco2*mco2*d(:,3).*d(:,8)/1e6;
d(:,13) = sso4*mso4*d(:,4).*d(:,8)/1e6;
d(:,14) = (d(:,5) - (d(:,6) + d(:,7)))./d(:,1);

% ==== Traitement des donn�es:
%   1. range les donn�es en ordre chronologique;
%   2. �limine les redondances temporelles pour une meme station (erreurs de saisie)
%   3. exporte un fichier de donn�es par station (avec en-tete EDAS)

% Tri par ordre chronologique
[t,k] = sort(t);
d = d(k,:);
si = si(k);
co = co(k);
% Recherche des redondances
k = find(diff(t) == 0);
kk = [];
for i = 1:length(k)
    if strcmp(si(k(i)),si(k(i)+1))
        kk = [kk;k(i)];
    end
end
t(kk) = [];
d(kk,:) = [];
si(kk) = [];
co(kk) = [];

so = [];
for i = 1:length(ST.cod)
    k = find(strcmp(si,ST.cod(i)));
    if ~isempty(k)
        so = [so i];
        tt = datevec(t(k));
        f = sprintf('%s/%s.DAT',pftp,ST.cod{i});
        fid = fopen(f,'wt');
        fprintf(fid, '# DATE: %s\r\n', datestr(now));
        fprintf(fid, '# TITL: %s: %s %s\r\n',rcode,ST.ali{i},ST.nom{i});
        fprintf(fid, '# SAMP: 0\r\n');
        fprintf(fid, '# OMGR: /g::o1en/2,,:o3,,:o4 /pe /nan:-1\r\n');
        fprintf(fid, '# CHAN: YYYY MM DD Dur�e_(j) Chlorures_(mmol/l/j) Carbonates_(mmol/l/j) Sulfates_(mmol/l/j) S/Cl S/C FluxCl_g/j) FluxC_(g/j) FluxS_(g/j) FluxH2O_(g/j)\r\n');
        fprintf(fid, '%4d-%02d-%02d %1.0f %0.2f %0.2f %0.2f %0.4f %0.4f %0.4f %0.4f %0.4f %0.4f\r\n',[tt(:,1:3),d(k,[1:4,9:14])]');
        fclose(fid);
        disp(sprintf('File: %s updated.',f))
    end
end
nx = length(so);

tm = datenum(tnow);
tn = min(t);

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
    if exist('OPT','var')
        G.fmt{ivg} = OPT.fmt;
        G.mks{ivg} = OPT.mks;
    end
end

% Renvoi des donn�es dans DOUT, sur la p�riode de temps G(end).lim
if nargout > 0
    for st = 1:nx
        stn = so(st);
        k = find(strcmp(si,ST.ali{stn}) & t>=G.lim{end}(1) & t<=G.lim{end}(2));
        DOUT(st).code = ST.cod{stn};
        DOUT(st).time = t(k);
        DOUT(st).data = d(k,:);
    end
end

if nargin > 3
    if nograph == 1, G = []; end
end

% ==== Trac� des graphes par site
for st = 1:nx
    stn = so(st);
    stitre = sprintf('%s: %s %s',ST.ali{stn},sname,ST.nom{stn});
	G.dat = [G.dat;{sprintf('%s%s',pdat,ST.cod{stn})}];
    
    for ig = ivg
          
        kn = find(strcmp(si,ST.cod{stn}));
        k = find(strcmp(si,ST.cod{stn}) & t>=G.lim{ig}(1) & t<=G.lim{ig}(2));
        if ~isempty(k), ke = k(end); else ke = []; end
        
        % Etat de la station
        acquis(stn) = round(100*length(k)*samp/diff(G.lim{ig}));
        tlast(stn) = t(kn(end));
        kl = find(t(k) >= G.lim{ig}(2)-last);
        if ~isempty(kl)
            etats(stn) = 100;
        else
            etats(stn) = 0;
        end
        % -----------> Veille de certaines stations
        if find(strcmp(ST.ali(stn),sveille))
            etats(stn) = -1;
        end
        if ig == 1
            sd = sprintf('%1.0f j, Cl %0.2f mmol/l/j, CO2 %0.2f mmol/l/j, SO4 %0.2f mmol/l/j, Tot %0.2f g, H2O %0.2f g, KOH %0.2f g, Vol %0.2f cm3, S/Cl %0.2f, S/C %0.2f, Cl %0.2f g/j, C %0.2f g/j, S %0.2f g/j, H2O %0.2f g/j',d(kn(end),:));
            mketat(etats(stn),tlast(stn),sd,lower(ST.cod{stn}),G.utc,acquis(stn))
        end
    
        % Titre et informations
        figure(1), clf, orient tall
		G.tit = gtitle(stitre,G.ext{ig});
		G.eta = [G.lim{ig}(2),etats(stn),acquis(stn)];

        if ~isempty(k)

			G.inf = {sprintf('Derni�re mesure: {\\bf%s %+d}',datestr(t(ke)),G.utc), ...
                sprintf('Chlorures = {\\bf%1.2f mmol/l/j}',d(ke,2)), ...
                sprintf('Carbonates = {\\bf%1.2f mmol/l/j}',d(ke,3)), ...
                sprintf('Sulfates = {\\bf%1.2f mmol/l/j}',d(ke,4)), ...
                sprintf('Rapport S/Cl = {\\bf%1.2f}',d(ke,9)), ...
                sprintf('Rapport S/C = {\\bf%1.2f}',d(ke,10)), ...
                sprintf('Volume total = {\\bf%1.2f cm^3}',d(ke,8)), ...
                sprintf('Flux Chlore = {\\bf%1.2f g/j}',d(ke,11)), ...
                sprintf('Flux Carbone = {\\bf%1.2f g/j}',d(ke,12)), ...
                sprintf('Flux Soufre = {\\bf%1.2f g/j}',d(ke,13)), ...
                sprintf('Flux Eau = {\\bf%1.2f g/j}',d(ke,14)), ...
                sprintf('Dur�e int�gration = {\\bf%1.0f j}',d(ke,1)), ...
                sprintf('Remarque = {\\bf%s}',char(co(ke))), ...
                };
		else
			G.inf = {''};
		end

        % Concentrations Cl- & CO2 & SO4
        subplot(6,1,1:2), extaxes
        plot(t(k),d(k,2:4),'.-','LineWidth',.1)
        set(gca,'XLim',G.lim{ig},'FontSize',8)
        datetick2('x',G.fmt{ig},'keeplimits')
        ylabel('Concentrations (mmol/l/j)')
        legend('Chlorures','Carbonates','Sulfates',2)
        
        % Rapports S/C & S/Cl
        subplot(6,1,3:4), extaxes
        plot(t(k),d(k,9:10),'.-','LineWidth',.1)
        set(gca,'XLim',G.lim{ig},'YScale','log','FontSize',8)
        datetick2('x',G.fmt{ig},'keeplimits')
        ylabel('Rapports')
        legend('S/Cl','S/C',2)
    
        % Flux Cl & C & S
        subplot(6,1,5), extaxes
        plot(t(k),d(k,11:13),'.-','LineWidth',.1)
        set(gca,'XLim',G.lim{ig},'FontSize',8)
        datetick2('x',G.fmt{ig},'keeplimits')
        ylabel('Flux massique (g/j)')
        legend('Chlore','Carbone','Soufre',2)
        
        % Flux eau condens�e
        subplot(6,1,6), extaxes
        plot(t(k),d(k,14),'.-','LineWidth',.1)
        set(gca,'XLim',G.lim{ig},'FontSize',8)
        datetick2('x',G.fmt{ig},'keeplimits')
        ylabel('Flux H_2O (g/j)')

        tlabel(G.lim{ig},G.utc)
        
        mkgraph(sprintf('%s_%s',lower(ST.cod{stn}),G.ext{ig}),G,OPT)
    end

end

% ==== Trac� des graphes de synth�se
stitre = sprintf('Synth�se R�seau %s',sname);
for ig = ivg

    k = find(t>=G.lim{ig}(1) & t<=G.lim{ig}(2));
    if ~isempty(k)
        ke = k(end);
        k1 = k(1);
    else
        ke = [];
        k1 = [];
    end

    % Titre et l�gende
    figure(1), clf, orient tall
	G.tit = gtitle(stitre,G.ext{ig});
	G.eta = [G.lim{ig}(2),rmean(etats(so)),rmean(acquis(so))];

    if isempty(k), break; end
    G.inf = {sprintf('Derni�re mesure: {\\bf%s %+d}',datestr(t(ke)),G.utc)};
    hold on
    nbsl = 4;
    for i = 1:nx
        xl = .1 + (i > nbsl)/nbsl;
        yl = .8 - .15*(mod(i-1,nbsl)+1);
        plot([xl xl]',yl+[.02 -.02]','-','Color',scolor(i))
        plot(xl+[.02 -.02],[yl yl],'-',xl,yl,'.','LineWidth',.1,'Color',scolor(i))
        if i == i0
            s = sprintf('%s (Blanc atmosph�rique)',ST.ali{so(i)});
        else
            s = ST.ali{so(i)};
        end
        text(xl+.03,yl,s,'Fontsize',8,'FontWeight','bold')
    end
    hold off
    
    % Rapport S/Cl
    subplot(6,1,1:2), extaxes
    hold on
    for i = 1:nx
        k = find(strcmp(si,ST.cod(so(i))) & t>=G.lim{ig}(1) & t<=G.lim{ig}(2));
        plot(t(k),d(k,9),'.-','LineWidth',.1,'Color',scolor(i))
    end
    hold off, box on
    set(gca,'XLim',G.lim{ig},'YScale','log','FontSize',8)
    datetick2('x',G.fmt{ig},'keeplimits')
	legend(ST.ali(so),2)
    ylabel(sprintf('Rapport S/Cl'))
    
    % Rapport S/C
    subplot(6,1,3:4), extaxes
    hold on
    for i = 1:nx
        k = find(strcmp(si,ST.cod(so(i))) & t>=G.lim{ig}(1) & t<=G.lim{ig}(2));
        plot(t(k),d(k,10),'.-','LineWidth',.1,'Color',scolor(i))
    end
    hold off, box on
    set(gca,'XLim',G.lim{ig},'YScale','log','FontSize',8)
    datetick2('x',G.fmt{ig},'keeplimits')
	legend(ST.ali(so),2)
    ylabel(sprintf('Rapport S/C'))

    % Eau condens�e
    subplot(6,1,5:6), extaxes
    hold on
    for i = 1:nx
        k = [];  k0 = [];
        kk = find(strcmp(si,ST.cod(so(i))) & t>=G.lim{ig}(1) & t<=G.lim{ig}(2));
        for j = 1:length(kk)
            kr = find(strcmp(si,ST.cod(i0)) & t == t(kk(j)));
            if ~isempty(kr)
                k0 = [k0;kr(1)];
                k = [k;kk(j)];
            end
        end
        plot(t(k),d(k,14)-d(k0,14),'.-','LineWidth',.1,'Color',scolor(i))
    end
    hold off, box on
    set(gca,'XLim',G.lim{ig},'FontSize',8)
    datetick2('x',G.fmt{ig},'keeplimits')
	legend(ST.ali(so),2)
    ylabel(sprintf('Flux H_2O relatif %s (g/j)',ST.ali{i0}))

    tlabel(G.lim{ig},G.utc)

    mkgraph(sprintf('%s_%s',rcode,G.ext{ig}),G,OPT)
end
close(1)

if ivg(1) == 1
    mketat(etats(so),max(tlast),sprintf('%s %d stations',stype,nx),rcode,G.utc,acquis(so))
    G.sta = [{rcode};lower(ST.cod(so))];
    G.ali = [{'BoJap'};ST.ali(so)];
    G.ext = G.ext(1:end-1); % graphes: tous sauf 'xxx'
    htmgraph(G);
end

timelog(rcode,2)

