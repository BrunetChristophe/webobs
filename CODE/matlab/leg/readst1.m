function S = readst(cd,ob,op);
%READST Importe les coordonn�es de stations Antilles.
%       READST lit le fichier "data/Stations_WGS84.txt" et renvoie une 
%       structure S contenant:
%           - S.cod = code station (5 caract�res)
%           - S.ali = alias de la station
%           - S.nom = nom complet de la station
%           - S.geo = vecteur de coordonn�es g�ographiques WGS84 [Lat Lon Alt]
%                     en degr�s d�cimaux et m�tre pour l'altitude
%           - S.wgs = vecteur de coordonn�es WGS84 UTM20 [Est Nord Alt] en m�tres
%           - S.utm = vecteur de coordonn�es Ste-Anne UTM20 [Est Nord Alt] en m�tres
%           - S.dte = date positionning (DATENUM format)
%           - S.pos = type position (0 = inconnue, 1 = Carte, 2 = GPS)
%           - S.ope = type de station (0 = ancienne station, 1 = op�rationnelle)
%           - S.obs = observatoire (OVSG, OVMP, MVO, SRU...)
%
%       READST(R) o� R = {R1,R2,..} est la liste des codes de r�seau,
%           s�lectionne les stations correspondantes. Exemples: 
%           READST({'Z ','L'}) renvoie toutes les stations sismiques CP et LB ;
%           READST('D9') renvoie les stations de distancem�trie.
%
%      READST(R,OBS,OP) sp�cifie l'observatoire (d�faut = tous) et le code OP
%      (pour sp�cifier toutes les stations, faire READST('','',...) )
%

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2001-08-17
%   Mise � jour : 2004-06-10

X = readconf;

% traitement des arguments d'entr�e
if nargin < 1
    cd = {''};        % d�faut = toutes les stations
else
    cd = cellstr(cd);
end
if nargin < 2
    ob = {'OVSG'};        % d�faut = OVSG seulement
else
    ob = cellstr(ob);
end
if nargin < 3
    op = 1;         % d�faut = stations op�rationnelles seulement
else
    op = 0;
end

% lecture du fichier
f = sprintf('%s/%s',X.RACINE_FICHIERS_CONFIGURATION,X.FILE_STATIONS);
[cod,ali,lat,lon,alt,pos,dte,ope,obs,nom] = textread(f,'%5c%q%n%n%n%n%q%n%q%q','commentstyle','shell');

% calcul des coordonn�es UTM (WGS84 et Ste-Anne) = geo2utmwgs
wgs = geo2utmwgs([lat lon alt]);
utm = geo2utmsa([lat lon alt]);

% s�lection des stations
k = [];
for i = 1:length(cd)
    for j = 1:length(ob)
        if isempty(cd{i})
            k = [k;find(ope >=op & strcmp(obs,ob(j)))];
        else
            k = [k;find(ope >=op & strcmp(cellstr(cod(:,3+find(cd{i}))),upper(deblank(cd{i}))) & strcmp(obs,ob(j)))];
        end
    end
end

% construction de la structure de sortie
S.cod = cellstr(cod(k,:));
S.ali = ali(k);
S.nom = nom(k);
S.geo = [lat(k) lon(k) alt(k)];
S.wgs = [wgs(k,1:2) alt(k)];
S.utm = [utm(k,1:2) alt(k)];
S.pos = pos(k);
S.ope = ope(k);
S.obs = obs(k);
dd = char(dte(k));
S.dte = datenum(str2double(cellstr(dd(:,1:4))),str2double(cellstr(dd(:,6:7))),str2double(cellstr(dd(:,9:10))));

disp(sprintf('Fichier: %s import� ("%s" "%s" OP>=%d %d/%d stations).',f,char(cd)',char(ob)',op,length(k),length(cod)))

