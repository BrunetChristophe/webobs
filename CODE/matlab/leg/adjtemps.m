function s=adjtemps(j)
%ADJTEMPS Adjectif temps.
%   ADJTEMPS(J) renvoie l'adjectif correspondant � la p�riode J en jour:
%       J = 1/24    'horaire'
%       J = 1       'journali�re'
%       J = 30      'mensuelle'
%       J = 365     'annuelle'

switch round(j*24)
case 1
    s = 'horaire';
case 24
    s = 'journali�re';
case 30*24
    s = 'mensuelle';
case 365*24
    s = 'annuelle';
otherwise
    s = sprintf('%g jour(s)',j);
end