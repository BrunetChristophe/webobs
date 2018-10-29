function [x,y] = ign0030(lc,n,xs,ys,e,l,p);
%IGN0030 Transformation de coordonn�es g�ographiques en coordonn�es projection Mercator Transverse.
%       [X,Y]=IGN0030(LC,N,XS,YS,E,LAM,PHI) renvoie les coordonn�es en projection 
%       Transverse Mercator X et Y � partir des param�tres:
%           LC = longitude origine par rapport au m�ridien origine
%           N = rayon de la sph�re interm�diaire
%           XS,YS = constantes sur X, Y
%           E = premi�re excentricit� de l'ellipsoide
%           LAM = longitude
%           PHI = latitide
%
%       Autres algorithmes utilis�s: IGN0001, IGN0028; IGN0052

%   Bibliographie:
%       I.G.N., Projection cartographique Mercator Transverse: Algorithmes, Notes Techniques NT/G 76, janvier 1995.
%   Auteur: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2003-01-13
%   Mise � jour : 2003-01-13

% Jeux d'essai
%lc = -0.05235987756; n = 6375697.8456; xs = 500000; ys = 0; e = 0.08248340004; l = -0.0959931089; p = 0.6065019151;

c = ign0028(e);
L = ign0001(p,e);
P = asin(sin(l - lc)./cosh(L));
LS = ign0001(P,0);
L = atan(sinh(L)./cos(l - lc));

z = complex(L,LS);
Z = n.*c(1).*z + n.*(c(2)*sin(2*z) + c(3)*sin(4*z) + c(4)*sin(6*z) + c(5)*sin(8*z));
x = imag(Z) + xs;
y = real(Z) + ys;
