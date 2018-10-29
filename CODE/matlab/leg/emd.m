function [md,en] = emd(t,d);
%EMD    Energie et magnitude de dur�e des s�ismes
%   [MD,EN] = EMD(T,D) renvoie la magnitude de dur�e MD et l'�nergie associ�e EN (en MJ)
%   � partir de la dur�e du signal T (en s) et la distance D (en km).
%
%   Auteur: F. Beauducel, OVSG-IPGP.
%   Cr��: 2005-06-28
%   Modifi�: 2005-06-29
%   R�f�rences: formule MD = [Lee and Lahr, 1975]
%               formule �nergie = [OVSG ?]

md = 2*log10(t) + 0.0035*d - .87;
en = 1e-6*10.^(2.9 + 1.92*md - .024*md.*md);
if isnan(en)
    en = 0;
end