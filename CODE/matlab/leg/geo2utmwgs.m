function enu=geo2utmwgs(llh,v);
%GEO2UTMSA Conversion coordonn�es WGS84 g�ographiques � UTM20
%       ENU=GEO2UTMWGS(LLH) retourne une matrice de coordonn�es UTM [E N U]
%       avec E = Est (m), N = Nord (m), U = Altitude (m), � partir d'une matrice 
%       de coordonn�es g�ographiques [LAT LON ELE] avec LAT = latitude (degr�s), 
%       LON = longitude (degr�s) et ELE = hauteur ellipsoidale (km).

%   Bibliographie:
%       I.G.N., Changement de syst�me g�od�sique: Algorithmes, Notes Techniques NT/G 80, janvier 1995.
%       I.G.N., Projection cartographique Mercator Transverse: Algorithmes, Notes Techniques NT/G 76, janvier 1995.
%       I.G.N., Transformation entre syst�mes g�od�siques, Service de G�od�sie et Nivellement, http://www.ign.fr, 1999/2002.
%   Auteur: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2003-12-02
%   Mise � jour : 2004-04-27

X = readconf;

% D�finition des constantes
D0 = 180/pi;
A1 = 6378137;            % WGS84 demi grand axe
F1 = 1/298.257223563;    % WGS84 aplatissement
K0 = 0.9996;             % UTM20 facteur d'�chelle au point origine
F0 = 20;                 % UTM20 n� du fuseau
P0 = 0/D0;               % UTM20 latitude origine (rad)
X0 = 500000;             % UTM20 Coordonn�e Est en projection du point origine (m)
Y0 = 0;                  % UTM20 Coordonn�e Nord en projection du point origine (m)

fgrd = sprintf('%s/%s',X.RACINE_DATA_MATLAB,X.DATA_GRILLE_GEOIDE); % fichier grille g�oide Guadeloupe

if nargin > 1
    vb = 1;
else
    vb = 0;
end
if vb
    disp('*** Transformation de coordonn�es WGS84 g�ographiques => UTM20')
    disp(sprintf(' WGS84 g�ographiques: Lat = %1.6f �, Lon = %1.6f �, H = %1.0f m',llh'))
end

% Conversion des donn�es
B1 = A1*(1 - F1);
E1 = sqrt((A1*A1 - B1*B1)/(A1*A1));

k = find(llh==-1);
llh(k) = NaN;
p1 = llh(:,1)/D0;        % Phi = Latitude (rad)
l1 = llh(:,2)/D0;        % Lambda = Longitude (rad)
h1 = llh(:,3);           % H = Hauteur (m)
L0 = (6*F0 - 183)/D0;    % UTM20 longitude origine (rad)

if vb
    disp(sprintf(' WGS84 g�ographiques: Phi = %g rad, Lam = %g rad, H = %1.3f m',p1,l1,h1))
end

% Transformation G�ographiques => UTM20 (HAYFORD 1909)

[LC,N,XS,YS] = ign0052(A1,E1,K0,L0,P0,X0,Y0);
[e2,n2] = ign0030(LC,N,XS,YS,E1,l1,p1);

if vb
    disp(sprintf(' WGS84 UTM20 : Est = %1.3f m, Nord = %1.3f m',e2,n2))
end

% Conversion altim�trique WGS84 => IGN1988 par m�thode de grille

[lam,phi,ngd,xgd] = textread(fgrd,'%n%n%n%n','headerlines',4);
k = find(~isnan(l1) & ~isnan(p1));
u2 = h1;
he = interp2(reshape(lam,[31,32]),reshape(phi,[31,32]),reshape(ngd,[31,32]),l1(k)*D0,p1(k)*D0);
u2(k) = h1(k) - he;

if vb
    disp(sprintf(' UTM20 WGS84 : altitude = %1.3f m',u2))
end

enu = [e2,n2,u2];
