function [nx,tx,sx,dx,tr,dr]=readidat(f)
%READIDAT Importe un fichier DAT inclino.
%       [NX,TX,SX,DX,TR,DR]=READIDAT(F) lit le fichier de calibration d'une station 
%       inclino donn�e ('sssiDATA.DAT') et retourne les variables :
%           NX = nombre de voies
%           TX = vecteur date et heure
%           SX = nom, type, unit� et code capteur (affich�)
%           DX = [ty,xx,pe,mn,mx,or]:
%                ty: num�ro de voie
%                xx: coeff en mV par unit� physique (mV/�rad/s� pour inclino)
%                pe: p�riode inclino (en s)
%                mn: valeur min (en mV)
%                mx: valeur max (en mV)
%                or: orientation inclino (en �N)
%           TR = vecteur date et heure
%           DR = valeurs de d�calage capteurs

%   Cr�ation: 2002-04-19
%   Modifi�: 2002-04-23

[data] = textread(f,'%[^\n]','commentstyle','shell');

ix = 0;
ir = 0;
nx = 0;
% NB: ne lit pas la premi�re ligne = nom de station
for i = 2:length(data)
    dd = data{i};
    if dd(18)~='R'
        [d,m,y,h,n,ty,nm,un,ch,co,xx,pe,mn,mx,or]=strread(dd,'%d-%d-%d%d:%d%d%s%s%s%s%n%n%n%n%n','delimiter',',');
        ix = ix + 1;
        tx(ix) = datenum(y,m,d,h,n,0);
        sx{ix} = {nm,un,ch,co};
        dx(ix,:) = [ty,xx,pe,mn,mx,or];
    else
        if nx==0
            nx = i - 2;
        end
        [d,m,y,h,n,ty,r1,r2,r3,r4,r5,r6,r7,r8]=strread(dd,'%d-%d-%d%d:%d%s%n%n%n%n%n%n%n%n','delimiter',',');
        ir = ir + 1;
        tr(ir) = datenum(y,m,d,h,n,0);
	dr(ir,:) = zeros(1,nx);
        dr(ir,1:8) = [r1,r2,r3,r4,r5,r6,r7,r8];
    end
end
% Remplace les p�riodes nulles par 1 (non inclino)
k = find(dx(:,3)==0);
dx(k,3) = dx(k,3) + 1;

disp(sprintf('Fichier: %s import�. %d canaux.',f,nx))
