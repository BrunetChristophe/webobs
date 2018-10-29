function [lc,n,xs,ys] = ign0052(a,e,k0,l0,p0,x0,y0);
%IGN0052 D�termination des param�tres de calcul pour la projection Mecator Transverse.
%       [LC,N,XS,YS]=IGN0052(A,E,K0,L0,P0,X0,Y0) renvoie la longitude origine LC, le
%       rayon de la sph�re interm�diaire N et les constances XS et YS � partir des param�tres:
%           A = demi-grand axe de l'ellipsoide
%           E = premi�re excentricit� de l'ellipsoide
%           K0 = facteur d'�chelle au point d'origine
%           L0 = longitude origine par rapport au m�ridien origine
%           P0 = latitude du point origine 
%           X0,Y0 = coordonn�es en projection du point origine
%
%       Autres algorithmes utilis�s: IGN0025, IGN0026

%   Bibliographie:
%       I.G.N., Projection cartographique Mercator Transverse: Algorithmes, Notes Techniques NT/G 76, janvier 1995.
%   Auteur: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2003-01-13
%   Mise � jour : 2003-01-13

% Jeux d'essai
%a = 6377563.3963; e = 0.08167337382; k0 = 0.9996012; l0 = -0.03490658504; p0 = 0.85521133347; x0 = 400000; y0 = -100000;

lc = l0;
n = k0*a;
xs = x0;
C = ign0025(e);
B = ign0026(p0,C);
ys = y0 - n*B;
