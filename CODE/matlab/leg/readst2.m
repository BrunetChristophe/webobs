function S = readst(cd,ob,op,tlim,clb);
%READST Importe la configuration des stations WEBOBS.
%       READST lit l'arborescence des r�pertoires "RACINE_DATA_STATIONS" 
%       et renvoie une structure S contenant:
%           - S.cod = code station (7 caract�res)
%           - S.ali = alias de la station
%           - S.dat = code de donn�es
%           - S.nom = nom complet de la station
%           - S.geo = vecteur de coordonn�es g�ographiques WGS84 [Lat Lon Alt]
%                     en degr�s d�cimaux et m�tre pour l'altitude
%           - S.wgs = vecteur de coordonn�es WGS84 UTM20 [Est Nord Alt] en m�tres
%           - S.utm = vecteur de coordonn�es Ste-Anne UTM20 [Est Nord Alt] en m�tres
%           - S.dte = date positionning (DATENUM format)
%           - S.pos = type position (0 = inconnue, 1 = Carte, 2 = GPS)
%           - S.ope = type de station (0 = ancienne station, 1 = op�rationnelle)
%           - S.deb = date de d�but / installation (format DATENUM)
%           - S.fin = date de fin / arret (format DATENUM)
%           - S.clb = sous-structure de calibration:
%                  .nx = nombre de voies
%                  .dt = vecteur dates de validit� (format DATENUM)
%                  .nv = vecteur num�ros de voies (1 � n);
%                  .nm = vecteur noms de voies;
%                  .un = vecteur unit�s;
%                  .ns = vecteur num�ros de s�rie capteur;
%                  .cd = vecteur codes capteur;
%                  .of = vecteur offsets;
%                  .et = vecteur facteur d'�talonnages;
%                  .ga = vecteur gains;
%                  .vn = vecteur valeur minimum (donn�e brute);
%                  .vm = vecteur valeur maximum (donn�e brute);
%                  .az = vecteur azimuth capteur (�N);
%                  .la = vecteur latitude capteur (�N);
%                  .lo = vecteur longitude capteur (�E);
%                  .al = vecteur altitude capteur (m);
%           Exemple: pour la station i, S.clb(i).nx est le nombre de voies, S.clb(i).ga
%           est un vecteur des gains correspondants aux voies S.clb(i).nv et aux dates
%           de validit� S.clb(i).dt
%
%       READST(R) o� R = {R1,R2,..} est la liste des codes de r�seau,
%           s�lectionne les stations correspondantes. Exemples: 
%           READST({'SZ ','SL'}) renvoie toutes les stations sismiques CP et LB;
%           READST('DD') renvoie les stations de distancem�trie.
%
%       READST(R,OBS,OP) sp�cifie l'observatoire (d�faut = tous) et le code OP
%       (pour sp�cifier toutes les stations, faire READST('','',...) )
%
%       READST(R,OBS,OP,0) ne lit pas les fichiers de calibration
%       

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2001-08-17
%   Mise � jour : 2009-09-22

X = readconf;

% traitement des arguments d'entr�e
if nargin < 1
    cd = {''};        % d�faut = toutes les stations
else
    cd = cellstr(cd);
end
if nargin < 2
    ob = {'G'};        % d�faut = OVSG seulement
else
    ob = cellstr(ob);
end
if nargin < 3
    op = 1;         % d�faut = stations op�rationnelles seulement
end
if nargin < 4
    tlim = [-Inf,Inf];
end
if size(tlim,1) < 2
	tlim = repmat(tlim,1,2);
end
if nargin < 5
    clb = 1;
end

cod = [];  ali = [];  lat = [];  lon = [];  alt = [];  pos = [];  dte = [];  ope = [];  dat = [];  fin = [];  nom = [];  deb = [];  typ = [];  tra = [];  C = [];

% liste des stations
for i = 1:length(ob)
    for ii = 1:length(cd)
        ST = dir(sprintf('%s/%s%s*',X.RACINE_DATA_STATIONS,ob{i},cd{ii}));
        for iii = 1:length(ST)
            cod = [cod;{ST(iii).name}];
            % lecture du fichier .conf
            f = sprintf('%s/%s/%s.conf',X.RACINE_DATA_STATIONS,ST(iii).name,ST(iii).name);
            if exist(f,'file')
                [x,v] = textread(f,'%s%q');
                for iiii = 1:length(x)
                    switch x{iiii}
                    case 'NOM'
                        nom = [nom;v(iiii)];
                    case 'ALIAS'
                        ali = [ali;v(iiii)];
                    case 'DATA_FILE'
                        dat = [dat;v(iiii)];
                    case 'VALIDE'
                        ope = [ope;str2double(v{iiii})];
                    case 'INSTALL_DATE'
                        deb = [deb;v(iiii)];
                    case 'END_DATE'
                        fin = [fin;v(iiii)];
                    case 'LAT_WGS84'
                        lat = [lat;str2double(v{iiii})];
                    case 'LON_WGS84'
                        lon = [lon;str2double(v{iiii})];
                    case 'ALTITUDE'
                        alt = [alt;str2double(v{iiii})];
                    case 'POS_DATE'
                        dte = [dte;v(iiii)];
                    case 'POS_TYPE'
                        pos = [pos;str2double(v{iiii})];
                    case 'TRANSMISSION'
                        tra = [tra;v(iiii)];
                    end
                end
            end
            % lecture du fichier type.txt
            f = sprintf('%s/%s/type.txt',X.RACINE_DATA_STATIONS,ST(iii).name);
            if exist(f,'file')
                xt = textread(f,'%s','delimiter','');
                if isempty(xt)
                    xt = {''};
                end
            else
                xt = {''};
            end
            typ = [typ;xt];
            if clb
                % lecture du fichier .clb
                f = sprintf('%s/%s/%s.clb',X.RACINE_DATA_STATIONS,ST(iii).name,ST(iii).name);
                CC = struct('nx',0,'dt',0,'nv',0,'nm','','un','','ns','','cd','','of',0,'et',0,'ga',0,'vn',0,'vm',0,'az',0,'la',0,'lo',0,'al',0);
                if exist(f,'file')
                    [y,m,d,h,n,nv,nm,un,ns,cc,of,et,ga,vn,vm,az,la,lo,al] = textread(f,'%d-%d-%d%d:%d%s%s%s%s%s%s%s%s%s%s%s%s%s%s%*[^\n]','delimiter','|','commentstyle','shell');
                    nn = 1;
                    for j = 1:length(y)
                        k = findstr(nv{j},'-');
                        if isempty(k)
                            j1 = str2double(nv{j});
                            j2 = j1;
                        else
                            j1 = str2double(nv{j}(1:(k-1)));
                            j2 = str2double(nv{j}((k+1):end));
                        end
                        for jj = j1:j2
                            CC.dt(nn) = datenum(y(j),m(j),d(j),h(j),n(j),0);
                            CC.nv(nn) = jj;
                            CC.nm{nn} = nm{j};
                            CC.un{nn} = un{j};
                            CC.ns{nn} = ns{j};
                            CC.cd{nn} = cc{j};
                            CC.of(nn) = str2double(of(j));
                            CC.et(nn) = str2double(et(j));
                            CC.ga(nn) = str2double(ga(j));
                            CC.vn(nn) = str2double(vn(j));
                            CC.vm(nn) = str2double(vm(j));
                            CC.az(nn) = str2double(az(j));
                            CC.la(nn) = str2double(la(j));
                            CC.lo(nn) = str2double(lo(j));
                            CC.al(nn) = str2double(al(j));
                            nn = nn + 1;
                        end
                        CC.nx = length(unique(CC.nv));
                    end
                end
                C = [C;CC];
            end
        end
    end
end

deb = isodatenum(deb);
fin = isodatenum(fin);

% S�lection des stations valides (op�rationnelles)
k = find(ope >= op & (deb <= tlim(2) | isnan(deb)) & (fin >= tlim(1) | isnan(fin)));

S.cod = cod(k);
S.ali = ali(k);
S.dat = dat(k);
S.nom = nom(k);
S.pos = pos(k);
S.ope = ope(k);
S.deb = deb(k);
S.fin = fin(k);
S.typ = typ(k);
S.tra = tra(k);
if clb
    S.clb = C(k);
end
S.geo = [lat(k),lon(k),alt(k)];
% calcul des coordonn�es UTM (WGS84 et Ste-Anne) = geo2utmwgs
if ~isempty(k)
	S.wgs = geo2utmwgs(S.geo);
	S.utm = geo2utmsa(S.geo);
	S.dte = isodatenum(dte(k));
else
	S.wgs = NaN*[1,1,1];
	S.utm = NaN*[1,1,1];
	S.dte = 0;
end

disp(sprintf('WEBOBS: %d stations imported from network "%s" ("%s" OP>=%d).',length(cod),char(cd)',char(ob)',op))

