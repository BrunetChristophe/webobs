function j = traduc(d)
%TRADUC Traduit les noms de jour et de mois

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2001-10-10
%   Mise � jour : 2001-10-10


% Jours de la semaine
F = {'lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche'};
A = {'Mon','Tue','Wed','Thu','Fri','Sat','Sun'};

% Mois de l'ann�e
F = [F,{'janvier','f�vrier','mars','avril','mai','juin','juillet','ao�t','septembre','octobre','novembre','d�cembre'}];
A = [A,{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'}];

k = find(strcmp(A,d));
if ~isempty(k)
    j = F{k};
else
    j = '?';
end