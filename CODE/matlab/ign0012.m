function [l,p,h] = ign0012(x,y,z,a,e,EPS);
%IGN0012 Transformation de coordonn�es cart�siennes en coordonn�es g�ographiques.
%       [LAM,PHI,HE]=IGN0012(X,Y,Z,A,E,EPS) renvoie les coordonn�es g�ographiques LAM
%       (longitude par rapport au m�ridien origine), PHI (latitude) et HE (auteur ellipsoidale)
%       � partir des param�tres:
%           X,Y,Z = coordonn�es cart�siennes
%           A = demi-grand axe de l'ellipsoide
%           E = premi�re excentricit� de l'ellipsoide
%           EPS = tol�rance de convergence, en rad (d�faut = 1E-11)

%   Bibliographie:
%       I.G.N., Changement de syst�me g�od�sique: Algorithmes, Notes Techniques NT/G 80, janvier 1995.
%   Auteur: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2003-01-13
%   Mise � jour : 2003-01-14


% Jeu d'essai
%a = 6378249.2; e = 0.08248325679; x = 6376064.695; y = 111294.623; z = 128984.725;

if nargin < 6
    EPS = 1e-11;
end
IMAX = 10;               % Imax = nombre maximum d'it�rations

R = sqrt(x.*x + y.*y);
l = 2*atan(y./(x + R));
p0 = atan(z./sqrt(x.*x + y.*y.*(1 - (a*e*e)./sqrt(x.*x + y.*y + z.*z))));
i = 0;
fin = 0;
while i < IMAX & ~fin
    i = i + 1;
    p1 = atan((z./R)./(1 - (a*e*e*cos(p0))./(R.*sqrt(1 - e*e*sin(p0).^2))));
    res = max(abs(p1-p0));
    if res < EPS
        fin = 1;
    end
    p0 = p1;
end
if fin
    p = p1;
    h = R./cos(p) - a./sqrt(1 - e*e*sin(p).^2);
else
    error('Probl�me de convergence...');
end
