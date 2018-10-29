function routine(mat)
%ROUTINE  Routines des r�seaux OVSG

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2003-07-02
%   Mise � jour : 2004-02-06

if nargin < 1
    mat = 1;
end

tnow = datevec(now);
X = readconf;

eval('acqui','disperr(''acqui'')');
eval('mkroutine','disperr(''mkroutine'')');
%if mat
%    eval('webstat(1)','disperr(''webstat'')');
%end

% statistiques acc�s web : attention tr�s lent (+5min)!!
%if tnow(5) < 5
%    eval('webstat','disperr(''webstat'')');
%end
    
% Affiche des informations sur l'erreur
function disperr(s)
disp(sprintf('* Matlab Error: Probl�me avec la fonction %s',upper(s)));
disp(lasterr);
