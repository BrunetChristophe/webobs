function r = indrefr(p,t,h)
%   INDREFR(P,T,H) calcule l'indice de r�fraction de l'air � partir des
%   valeurs de pression P (en mmHg), temp�rature s�che T (en �C) et 
%   humidit� relative H (en %), pour le Rangemaster III.

%   (c) F. Beauducel, OVSG 2001.
%   R�f�rences: - http://www.agsci.kvl.dk/~bek/relhum.htm (calcul de Tw)
%               - GEODAT.FOR [Ruegg, 1991] (calcul de r)

Am = [0.001388246;
      0.003671;
      4.6181768;
      0.000222;
      0.00067];
Bm = 0.060702;
Xng = 284.51;
Xn0 = 309.6;

% Calcul de la temp�rature humide Tw � partir de l'humidit� relative h
E = (h/100).*0.611.*exp(17.27*t./(t + 237.3));
Td = (116.9 + 237.3*log(E))./(16.78 - log(E));
Gamma = 0.00066*p*0.13328;
Delta = 4098.*E./((t + 237.3).^2);
Tw = (Gamma.*t + Delta.*Td)./(Gamma + Delta);

% Calcul de l'indice de r�fraction de l'air pour le Rangemaster
a = Am(1)*Xng./(1 + Am(2).*t);
b = Bm./(1 + Am(2).*t);
Ps = Am(3)*exp(0.071*Tw - Am(4)*Tw.*Tw);
Ph = Am(5)*(t - Tw).*p;
r = (a.*p - b.*(Ps - Ph));
