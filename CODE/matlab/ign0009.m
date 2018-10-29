function [x,y,z] = ign0009(l,p,he,a,e);
%IGN0009 Transformation de coordonn�es g�ographiques ellipsoidales en coordonn�es cart�siennes.
%       [X,Y,Z]=IGN0009(LAM,PHI,HE,A,E) renvoie les coordonn�es cart�siennes X,Y,Z � 
%       partir des param�tres:
%           LAM = longitude par rapport au m�ridien origine
%           PHI = latitude
%           HE = hauteur au dessus de l'ellipsoide
%           A = demi-grand axe de l'ellipsoide
%           E = premi�re excentricit� de l'ellipsoide
%
%       Autre algorithme utilis�: IGN0021

%   Bibliographie:
%       I.G.N., Changement de syst�me g�od�sique: Algorithmes, Notes Techniques NT/G 80, janvier 1995.
%   Auteur: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2003-01-13
%   Mise � jour : 2003-01-13

N =  ign0021(p,a,e);

x = (N + he).*cos(p).*cos(l);
y = (N + he).*cos(p).*sin(l);
z = (N.*(1 - e*e) + he).*sin(p);

