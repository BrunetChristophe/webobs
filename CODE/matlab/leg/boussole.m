function s=boussole(az,x)
%BOUSSOLE Donne la direction!
%   BOUSSOLE(AZ) retourne une chaine de caract�re donnant une abr�viation 
%   de la direction ('N','SSE',...) � partir de l'azimuth AZ (en radians, 
%   conventions trogonom�triques).
%
%   BOUSSOLE(AZ,1) retourne le texte complet ('au nord','� l'est-sud-est',...).

%   Auteur: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2005-08-09
%   Mise � jour : 2005-08-11

na = {'E','ENE','NE','NNE','N','NNW','NW','WNW','W','WSW','SW','SSW','S','SSE','SE','ESE'};
nc = {'� l''est','� l''est-nord-est','au nord-est','au nord-nord-est','au nord','au nord-nord-ouest','au nord-ouest','� l''ouest-nord-ouest','� l''ouest','� l''ouest-sud-ouest','au sud-ouest','au sud-sud-ouest','au sud','au sud-sud-est','au sud-est','� l''est-sud-est'};

sz = length(na);

k = mod(round(az*sz/(2*pi)),sz) + 1;

if nargin < 2
    s = na{k};
else
    s = nc{k};
end
