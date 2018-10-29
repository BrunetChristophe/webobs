function pp = mketat(p,t,d,s,tu,a)
%MKETAT Ecrit l'�tat des stations
%       MKETAT(P,T,D,S,TU,A) exporte les derni�res donn�es dans "data/etats.dat":
%           - P = pourcentage �tat station
%           - T = date et heure derni�re donn�e
%           - D = chaine des derni�res donn�es ou nombre de stations du r�seau
%           - S = code station (minuscules) ou r�seau (majuscules)
%           - TU = fuseau horaire (0 = TU, -4 = local)
%           - A = pourcentage acquisition
%
%       Si P ou A est un vecteur, la moyenne est calcul�e.

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2001-06-01
%   Mise � jour : 2004-06-22

X = readconf;

f = sprintf('%s/data/etats.dat',X.RACINE_OUTPUT_MATLAB);

if length(p) > 1
    p = mean(p(find(p ~= -1)));
end
p = round(p);
a = round(mean(a));

if (p < 50 | a <= 50) & p ~= -1
    if p < 50
        if t < now-1
            st = 'x';
        else
            st = 'X';
        end
    else
        st = '?';
    end
else
    st = '-';
end

if isnan(t)
    tv = zeros(1,6);
else
    tv = datevec(t);
end
fid = fopen(f,'at');
fprintf(fid,'%s %11s %03d %03d %4d-%02d-%02d %02d:%02d:%02.0f %+d %s\n',st,s,p,a,tv,tu,d);
fclose(fid);
disp(sprintf('File: %s updated (%s).',f,s))

if nargout
    pp = p;
end
