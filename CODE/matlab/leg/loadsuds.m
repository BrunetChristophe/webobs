function [tt,dd] = loadsuds(fn,dec,fhz,sfr,ptmp)
%LOADSUDS Importe un fichier SUDS
%   [T,D,IRIG]=LOADSUDS(F,DEC,FHZ,VOIES,PTMP) renvoie un vecteur temps T, une matrice 
%   de donn�es D � partir de la liste des fichiers F, de 
%   la d�cimation DEC, de la fr�quence d'�chantillonnage FHZ, de la liste des VOIES.
%
%   Auteur: F. Beauducel, OVSG-IPGP
%   Cr�ation: 2004-07-06
%   Modifi�: 2004-07-06

X = readconf;

if nargin < 2
    dec = 20;
end
if nargin < 3
    fhz = 100.2;
end
if nargin < 4
    f = sprintf('%s/%s',X.RACINE_FICHIERS_CONFIGURATION,X.FILE_VOIES_SEFRAN);
    [sfr,sfg] = textread(f,'%s%n','commentstyle','shell');
end
if nargin < 5
    ptmp = sprintf('%s/tmp',X.RACINE_OUTPUT_MATLAB);
end

fa = fn((end-16):end);
zd = [str2double(fa(1:2)),str2double(fa(3:4)),str2double(fa(6:7)),str2double(fa(8:9)),str2double(fa(10:11)),str2double(fa(12:13))];

% traitement des secondes (fichiers sans code IRIG: [A-F]X)
if ~isempty(find(isnan(zd(6))))
    zd(6) = (double(fa(11)) - double('A'))*10 + str2double(fa(12));
    ir = 0;
else
    ir = 1;
end
tf = datenum([zd(1) + 2000,zd(2:end)]);

fnam = fn((end-12):end);

delete(sprintf('%s/*.*',ptmp));
unix(sprintf('cp -f %s %s/.',fn,ptmp));
unix(sprintf('%s %s/%s >&! /dev/null',X.PRGM_SUD2MAT,ptmp,fnam));
ff = sprintf('%s/tmp.mat',ptmp);
vn = who('-file',ff);
va = char(vn);
for i = 1:length(sfr)
    ii = find(strcmp(sfr(i),cellstr(va(:,1:4))));
    if ~isempty(ii)
        S = load(ff,vn{ii});
        eval(sprintf('dd(:,i) = S.%s;',vn{ii}));
    end
end

% fichier avec code IRIG: tf = heure de d�but de fichier (exact)
tt = (tf + (1:size(dd,1))/(fhz*86400))';
% fichiers sans code IRIG: tf = heure de fermeture du fichier (approximatif)
if ir == 0
    tt = tt - diff(tt([1 end]));
end

if dec ~= 1
    tt = rdecim(tt,dec);
    dd = rdecim(dd,dec);
end
disp(sprintf('Fichier: %s import�.',fn));

