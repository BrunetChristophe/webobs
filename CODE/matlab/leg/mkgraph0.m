function mkgraph(f,G,r,ps,ds)
%MKGRAPH Cr�� un fichier PNG de la figure courante.
%   MKGRAPH(F,P) cr�� un fichier F.png � partir de la figure courante dans le r�pertoire P:
%   puis le copie dans le r�pertoire Web MATLAB_PATH_IMAGES. La r�solution par d�faut est
%   d�finie par la variable de config MKGRAPH_VALUE_PPI.
%
%   MKGRAPH(F,P,R) sp�cifie la r�solution R ou en option avec [R,1] la cr�ation d'une 
%   miniature MKGRAPH_VALUE_VIGNETTE fois plus petite en taille au format JPG (uniquement 
%   dans le r�pertoire d'images Web).
%
%   MKGRAPH(F,P,R,PS) cr�� �galement un fichier Postscript F.ps dans images/.
%
%   Attention: MKGRAPH n�cessite un display X actif pour produire une image PNG; si ce 
%   n'est pas le cas, une image PS est cr��e et elle est ensuite convertie en fichier
%   PNG avec la fonction unix "/usr/bin/convert".

%   Auteurs: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2002-12-03
%   Mise � jour : 2004-10-18

X = readconf;

if nargin < 3, r = str2double(X.MKGRAPH_VALUE_PPI); end
if nargin < 4, ps = 0; end
if nargin < 5, ds = X.MKSPEC_PATH_WEB; end
    
if length(r) > 1
    vign = r(2);
else
    vign = 0;
end

scpr = '\copyright FB, OVSG-IPGP';

% Interpr�tation de la structure G
if isstruct(G)
    p = sprintf('%s/%s',X.RACINE_FTP,G.ftp);
    if isfield(G,'ico')
        vign = G.ico;
    end
    if isfield(G,'dsp')
        ds = G.dsp;
    end
    if isfield(G,'cpr')
        if isfield(G,'lg2')
            matpad(G.cpr,0,G.lg2,f);
        else
            matpad(G.cpr,0,[],f);
        end
    end
else
    p = G;
end

pwww = X.RACINE_WEB;
pimg = X.MATLAB_PATH_IMAGES;
convert = X.PRGM_CONVERT;
rvign = str2double(X.MKGRAPH_VALUE_VIGNETTE);

if findstr(f,'_xxx')
    spec = 1;
    phtm = ds;
    ps = 1;
else
    spec = 0;
    phtm = X.MKGRAPH_PATH_WEB;
end

if strcmp(get(gcf,'XDisplay'),'nodisplay')
    print(gcf,'-dpsc',sprintf('%s/%s.ps',pimg,f));
    disp(sprintf('Graphe:  %s/%s.ps cr��.',pimg,f))
    flagps = 1;
    unix(sprintf('%s -colors 256 -density %dx%d %s/%s.ps %s/%s.png',convert,r(1),r(1),pimg,f,p,f));
else    
    print(gcf,'-dpng','-painters',sprintf('-r%d',r(1)),sprintf('%s/%s.png',p,f))
    if vign
        IM = imfinfo(sprintf('%s/%s.png',p,f));
        ims = [IM.Width IM.Height];
        unix(sprintf('%s -scale %dx%d %s/%s.png %s/%s/%s.jpg',convert,round(ims(1)/rvign),round(ims(2)/rvign),p,f,pwww,phtm,f));
    end
    flagps = 0;
end
disp(sprintf('Graphe:  %s/%s.png cr��.',p,f))
unix(sprintf('cp -f %s/%s.png %s/%s/.',p,f,pwww,phtm));
if vign
    disp(sprintf('Graphe:  Vignette %s.jpg cr��e.',f));
end
if spec
    print(gcf,'-dpsc','-painters',sprintf('%s/%s.ps',p,f));
    disp(sprintf('Graphe:  %s/%s.ps cr��.',p,f))
	unix(sprintf('cp -f %s/%s.ps %s/%s/.',p,f,pwww,phtm));
end

%unix(sprintf('/usr/bin/convert -colors 256 -density %dx%d images/%s.ps %s/%s.png',r,r,f,p,f));
%unix(sprintf('/usr/bin/gs -sDEVICE=png256 -sOutputFile=%s/%s.png -r100 -dNOPAUSE -dBATCH -q %s.ps',p,f,f));

