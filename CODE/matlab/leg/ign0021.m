function n = ign0021(p,a,e);
%IGN0021 Calcul de la grande normale de l'ellipsoide.
%       N=IGN0009(PHI,A,E) renvoie la grande normale N � partir des param�tres:
%           PHI = latitude
%           A = demi-grand axe de l'ellipsoide
%           E = premi�re excentricit� de l'ellipsoide
%
%       Autre algorithme utilis�: IGN0021

%   Bibliographie:
%       I.G.N., Changement de syst�me g�od�sique: Algorithmes, Notes Techniques NT/G 80, janvier 1995.
%   Auteur: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2003-01-13
%   Mise � jour : 2003-01-13

n =  a./sqrt(1 - e*e*sin(p).^2);
