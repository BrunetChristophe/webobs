function sismoress(mat,n)
%SISMORESS Traitement des s�ismes ressentis
%       SISMORESS traite le dernier s�isme localis� (hypoovsg.txt) et calcule le PGA th�orique
%       sur l'archipel de Guadeloupe (loi d'att�nuation [OVSG, 2004]). Si une zone d�passe 
%       un seuil d'dacc�l�ration, un communiqu� est produit et envoy� par e-mail.
%
%       SISMORESS(MAT,N) recharge les informations g�ographiques (lignes de cotes, villes, etc...)
%       si MAT == 0 et fait le traitement sur les N derniers s�ismes localis�s. Si N <= 0, fait
%       le calcul sur un s�isme test -N.

%   Auteur: F. Beauducel, OVSG-IPGP
%   Cr�ation : 2005-01-12
%   Mise � jour : 2007-08-09

X = readconf;

rcode = 'SISMORESS';
timelog(rcode,1);

if nargin < 1,  mat = 1;  end
if nargin < 2,  n = 1;  end

if n <= 0
    test = abs(n) + 1;
    n = 1;
else
    test = 0;
end

% D�finition des variables
xylim = [-64 -59.7 14.25 18.4];                % limites carte hypo (en �)
dxy = .05;                                       % pas de la grille XY (en �)
pgamin = 2;                                      % PGA minimum (en milli g)
pgamsk = [1,2,5,10,20,50,100,200,500,1000,2000]; % limites PGA �quivalent �chelle MSK (en milli g)
lwmsk = [.1,.25,.5,1,1.5,2,2.5,3,3.5,4,5];       % largeur des lignes iso
%nommag = {'micro','minor','light','moderate','strong','major','great',''};
nommag = {'micros�isme','s�isme mineur','faible s�isme','s�isme mod�r�','s�isme important','s�isme fort','tr�s fort s�isme','s�isme majeur'}; % <2, 2-3, 3-4, 4-5, 5-6, 6-7, 7-8, >8
nommsk = {'non ressentie';
          'rarement ressentie';
          'faiblement ressentie';
          'largement ressentie';
          'secousse forte';
          'd�g�ts l�gers probables';
          'd�g�ts probables';
          'd�g�ts importants probables';
          'destructions probables';
          'destructions importantes probables';
          'catastrophe probable'};
nomres = {'non ressenti';'tr�s faible';'faible';'l�g�re';'mod�r�e';'forte';'tr�s forte';'s�v�re';'violente';'extr�me'};
nomdeg = {'aucun';'aucun';'aucun';'aucun';'tr�s l�gers';'l�gers';'mod�r�s';'moyens';'importants';'g�n�ralis�s'};
txtb3 = sprintf('FB+CAH (c) OVSG-IPGP %s - Calculs bas�s sur localisation OVSG + loi d''att�nuation B-Cube [Beauducel et al., 2004]',datestr(now,'yyyy'));
tsok = [2,13,14,15];			% types de s�isme OK pour calcul B3

loi = [0.611377,-0.00584334,-3.216674];     % loi 2 (avec M USGS)
efsite = 3;									% facteur d'effets de sites
dhpmin = 5;									% distance hypocentrale minimale (effet de saturation) en km
latkm = 6370*pi/180;                        % valeur du degr� latitude (en km)
lonkm = latkm*cos(16*pi/180);               % valeur du degr� longitude (en km)
gris = .8*[1,1,1];                          % couleur gris clair
mer = [.7,.9,1];							% couleur bleu mer
ppi = 150;                                  % r�solution PPI

% Colormap JET d�grad�e
sjet = jet(256);
z = repmat(linspace(0,1,length(sjet))',1,3);
sjet = sjet.*z + (1-z);

pgra = sprintf('%s/Sismologie/B3',X.RACINE_FTP);
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% DEBUG
% Faire une boucle pour utiliser tous les hypoovsg_* ou remplacer tail
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
f1 = sprintf('%s/Sismologie/Hypocentres/hypoovsg_*.txt',X.RACINE_FTP);
f2 = sprintf('%s/lasthypo.txt',pgra);
f3 = sprintf('%s/lasthypo.pdf',pgra);
f4 = sprintf('%s/lasthypo.jpg',pgra);
ftmp = '/tmp/lasthypo.ps';
mtmp = '/tmp/mailb3.txt';
ttmp = '/tmp/hypob3.txt';
flogo1 = sprintf('%s/%s',X.RACINE_WEB,X.IMAGE_LOGO_OVSGIPGP);
%flogo2 = sprintf('%s/%s',X.RACINE_WEB,X.IMAGE_LOGO_OVSG);
flogo3 = sprintf('%s/%s',X.RACINE_WEB,X.IMAGE_LOGO_B3);

% Test: chargement si la sauvegarde Matlab existe
f_save = sprintf('%s/past/%s_past.mat',X.RACINE_OUTPUT_MATLAB,rcode);
if mat & exist(f_save,'file')
    load(f_save,'c_pta','A1','A3','CS','IC');
    disp(sprintf('Fichier: %s import�.',f_save))
else
    disp('Pas de sauvegarde Matlab. Chargement de toutes les donn�es...');
    f = sprintf('%s/antille2.bln',X.RACINE_DATA_MATLAB);
    c_ant = ibln(f);
    c_pta = econtour(c_ant,[],xylim);
    A1 = imread(flogo1);
    %A2 = imread(flogo2);
    A3 = imread(flogo3);
    f = sprintf('%s/Infos_Communes.txt',X.RACINE_FICHIERS_CONFIGURATION);
    [IC.lon,IC.lat,IC.nom] = textread(f,'%n%n%q','commentstyle','shell');
    CS = readcs;
   
    save(f_save);
    disp(sprintf('Fichier: %s sauvegard�.',f_save))
end


% Chargement des s�ismes localis�s
unix(sprintf('tail -q -n %d %s > %s',n + 1,f1,ttmp));    % NB: N + 1 car READHYP ignore la premi�re ligne du fichier TTMP
DH = readhyp(ttmp);

% Construction de la grille XY
[x,y] = meshgrid(xylim(1):dxy:xylim(2),xylim(3):dxy:xylim(4));

for i = 1:length(DH.tps)

    switch test-1
    case 0 
        DH.tps(i) = datenum(1843,2,8,14,40,00); DH.lat(i) = 16.733; DH.lon(i) = -61.167; DH.dep(i) = 50; DH.mag(i) = 8; DH.typ(i) = 2;
    case 1
        DH.tps(i) = datenum(1851,5,16,9,20,0); DH.lat(i) = 16.0; DH.lon(i) = -61.5; DH.dep(i) = 20; DH.mag(i) = 6; DH.typ(i) = 2;
    case 2
        DH.tps(i) = datenum(1897,4,29,10,25,2); DH.lat(i) = 16.18; DH.lon(i) = -61.55; DH.dep(i) = 20; DH.mag(i) = 5.5; DH.typ(i) = 2;
    case 3
        DH.tps(i) = datenum(2004,11,21,11,41,7); DH.lat(i) = 15.684; DH.lon(i) = -61.71; DH.dep(i) = 14.0; DH.mag(i) = 6.3; DH.typ(i) = 2;
        tnow = datenum(2004,11,21,10,0,0);
    case 4
        DH.tps(i) = datenum(2004,12,27,20,58,14); DH.lat(i) = 15.823; DH.lon(i) = -61.602; DH.dep(i) = 9.6; DH.mag(i) = 4.7; DH.typ(i) = 2;
        tnow = datenum(2004,12,27,17,30,0);
    case 5
        DH.tps(i) = datenum(2005,2,14,18,05,59); DH.lat(i) = 15.81; DH.lon(i) = -61.58; DH.dep(i) = 12; DH.mag(i) = 5.7; DH.typ(i) = 2;
        tnow = datenum(2005,2,14,16,41,0);
    case 6
        DH.tps(i) = datenum(1985,3,16,14,54,0); DH.lat(i) = 17.02; DH.lon(i) = -62.28; DH.dep(i) = 8.2; DH.mag(i) = 6.2; DH.typ(i) = 2;
    case 7
        DH.tps(i) = datenum(2005,9,26,11,15,0); DH.lat(i) = 16.38; DH.lon(i) = -61.31; DH.dep(i) = 15; DH.mag(i) = 5.5; DH.typ(i) = 2;
        tnow = datenum(2005,9,26,7,30,0);
    case 8
        DH.tps(i) = datenum(1976,3,10,9,5,1); DH.lat(i) = 16+50.4/60; DH.lon(i) = -61-3.6/60; DH.dep(i) = 56; DH.mag(i) = 5.7; DH.typ(i) = 2;
    case 9
        DH.tps(i) = datenum(1974,10,8,9,50,0); DH.lat(i) = 17.37; DH.lon(i) = -61.99; DH.dep(i) = 41; DH.mag(i) = 7.4; DH.typ(i) = 2;
    case 10
        DH.tps(i) = datenum(1976,8,16,23,40,0); DH.lat(i) = 16.05; DH.lon(i) = -61.66; DH.dep(i) = 5; DH.mag(i) = 4.2; DH.typ(i) = 13;
    case 11
        DH.tps(i) = datenum(1961,11,2,23,3,0); DH.lat(i) = 17.13; DH.lon(i) = -62.68; DH.dep(i) = 20; DH.mag(i) = 5.5; DH.typ(i) = 2;
    case 12
        DH.tps(i) = datenum(1690,2,26,17,0,0); DH.lat(i) = 17.02; DH.lon(i) = -62.28; DH.dep(i) = 15; DH.mag(i) = 7.5; DH.typ(i) = 2;
    case 13
        DH.tps(i) = datenum(1897,4,29,10,25,1); DH.lat(i) = 16+25/60; DH.lon(i) = -61-56/60; DH.dep(i) = 15; DH.mag(i) = 6.5; DH.typ(i) = 2;
    case 14
        DH.tps(i) = datenum(1897,5,20,0,0,0); DH.lat(i) = 16.5; DH.lon(i) = -62.02; DH.dep(i) = 20; DH.mag(i) = 6.5; DH.typ(i) = 2;
    case 15
        DH.tps(i) = datenum(1935,11,10,18,40,0); DH.lat(i) = 16.79; DH.lon(i) = -62.33; DH.dep(i) = 15; DH.mag(i) = 5.8; DH.typ(i) = 2;
    case 16
        DH.tps(i) = datenum(2007,11,29,19,00,0); DH.lat(i) = 14.99; DH.lon(i) = -61.03; DH.dep(i) = 152; DH.mag(i) = 8.3; DH.typ(i) = 2;
    case 17
        DH.tps(i) = datenum(2007,11,29,19,00,0); DH.lat(i) = 14.99; DH.lon(i) = -61.03; DH.dep(i) = 75; DH.mag(i) = 7.3; DH.typ(i) = 2;

    otherwise
    end
    % ==========================================================

	vtps = datevec(DH.tps(i));
    fnam = sprintf('%4d%02d%02dT%02d%02d%02.0f_b3',vtps);
	pam = sprintf('%4d/%02d',vtps(1:2));
    if test
        fgra = sprintf('%s/simulations/%s.pdf',pgra,fnam);
        fjpg = sprintf('%s/simulations/%s.jpg',pgra,fnam);
		ftxt = sprintf('%s/simulations/%s.txt',pgra,fnam);
    else
        fgra = sprintf('%s/ressentis/%s/%s.pdf',pgra,pam,fnam);
        fjpg = sprintf('%s/ressentis/%s/%s.jpg',pgra,pam,fnam);
		unix(sprintf('mkdir -p %s/ressentis/%s',pgra,pam));
		ftxt = sprintf('%s/traites/%s/%s.txt',pgra,pam,fnam);
		unix(sprintf('mkdir -p %s/traites/%s',pgra,pam));
    end

    if i == 1
        figure, orient tall
        set(gcf,'PaperType','A4');
        pps = [.2,.2,7.8677,11.2929];
        set(gcf,'PaperPosition',pps);
    end
    
    
    if (~exist(ftxt,'file') | test) & ~isempty(find(DH.typ(i) == tsok))
		tnow = now;
		%Pour mettre � jour les cartes en gardant la date de cr�ation du fichier...
		%if ~test & exist(fgra,'file')
		%    D = dir(fgra);
		%    tnow = datesys2num(D.date);
		%end

        % distance hypocentrale sur la grille XY
        dhp = sqrt(((x - DH.lon(i))*lonkm).^2 + ((y - DH.lat(i))*latkm).^2 + DH.dep(i).^2);
        % PGA max au sol (loi major�e x3) sur la grille XY
        pga = efsite*1000*10.^(loi(1)*DH.mag(i) + loi(2)*dhp - log10(dhp) + loi(3));
		
        %vpga = interp2(x,y,pga,IC.lon,IC.lat);
        %vdhp = interp2(x,y,dhp,IC.lon,IC.lat);
		vdhp = sqrt(((IC.lon - DH.lon(i))*lonkm).^2 + ((IC.lat - DH.lat(i))*latkm).^2 + DH.dep(i).^2);
		k = find(vdhp < dhpmin);
		vdhp(k) = dhpmin;
		vpga = efsite*1000*10.^(loi(1)*DH.mag(i) + loi(2)*vdhp - log10(vdhp) + loi(3));
		
        [xx,iv] = sort(-vpga);
        if max(vpga) >= pgamin
            ress = 1;
            k = find(vpga >= pgamin);
            vmsk = ones(size(k));
            ss = cell(size(k));
            for ii = 1:length(ss)
                kk = find(vpga(iv(ii)) < pgamsk);
                vmsk(ii) = kk(1) - 1;
                og = 10^(floor(log10(vpga(iv(ii)))) - 1);
                ss{ii} = sprintf('{\\bf%s � %s} : %s (%1.0f mg)',romanx(vmsk(ii)-1),romanx(vmsk(ii)),IC.nom{iv(ii)},round(vpga(iv(ii))/og)*og);
            end
        else
            ress = 0;
        end

        % Archivage du traitement
        fid = fopen(ftxt,'wt');
        fprintf(fid,repmat('*',1,80));
        fprintf(fid,'\n* Traitement automatique Loi d''att�nuation B3 [Beauducel et al., 2004]\n');
        fprintf(fid,'* %s (locales)\n',datestr(tnow));
        fprintf(fid,'* Hypocentre OVSG: %s TU, MD = %1.1f, Type %s\n',datestr(DH.tps(i)),DH.mag(i),CS{2,DH.typ(i)});
        fprintf(fid,'*                  %g �N %g �E %g km\n',DH.lat(i),DH.lon(i),DH.dep(i));
        fprintf(fid,'* Distance hypocentrale et PGA calcul� (estimation effets de sites = x %g):\n',efsite);
        for ii = 1:length(vpga)
            fprintf(fid,'\t%s: %0.1f km - %g mg\n',IC.nom{iv(ii)},vdhp(iv(ii)),vpga(iv(ii)));
        end
        fprintf(fid,repmat('*',1,80));
        fclose(fid);
        disp(sprintf('Fichier: %s cr��.',ftxt));
        
        % ------------------------------------------------------------------------------
        % Si ressenti, contruction de la page et traitements
        if ress | test
            clf
    
            isz1 = size(A1);
            %isz2 = size(A2);
            isz3 = size(A3);

            pos = [0.03,1-isz1(1)/(ppi*pps(4)),isz1(2)/(ppi*pps(3)),isz1(1)/(ppi*pps(4))];
            % logos IPGP et OVSG
            h1 = axes('Position',pos,'Visible','off');
            image(A1), axis off
            %pos = [sum(pos([1,3])),1-isz2(1)/(ppi*pps(4)),isz2(2)/(ppi*pps(3)),isz2(1)/(ppi*pps(4))];
            %h2 = axes('Position',pos,'Visible','off');
            %image(A2), axis off
            % en-tete
            h3 = axes('Position',[sum(pos([1,3]))+.03,pos(2),.95-sum(pos([1,3])),pos(4)]);
            if test
                text(.3,0,'SIMULATION','FontSize',72,'FontWeight','bold','Color','y','Rotation',15,'HorizontalAlignment','center');
            end
            text(0,1,{'Rapport pr�liminaire de s�isme','concernant la Guadeloupe'}, ...
                'VerticalAlignment','top','FontSize',18,'FontWeight','bold','Color',.3*[0,0,0]);
            text(0,0,{'{\bfObservatoire Volcanologique et Sismologique de Guadeloupe - IPGP}', ...
                      'Le Houelmont - 97113 Gourbeyre - Guadeloupe (FWI)', ...
                      'T�l: +590 (0)590 99 11 33 - Fax: +590 (0)590 99 11 34 - infos@ovsg.univ-ag.fr - www.ipgp.jussieu.fr'}, ...
                 'VerticalAlignment','bottom','FontSize',8,'Color',.3*[0,0,0]);
            set(gca,'YLim',[0,1]), axis off
            % logo B3
            pos = [.95 - isz3(2)/(ppi*pps(4)),1-isz3(1)/(ppi*pps(4)),isz3(2)/(ppi*pps(3)),isz3(1)/(ppi*pps(4))];
            h4 = axes('Position',pos,'Visible','off');
            image(A3), axis off

            % titre
            h5 = axes('Position',[.05,.75,.9,.15]);
            if ress
                text(1,1,sprintf('Gourbeyre, le %s %s %s %s locales',datestr(tnow,'dd'),traduc(datestr(tnow,'mmm')),datestr(tnow,'yyyy'),datestr(tnow,'HH:MM')), ...
                     'horizontalAlignment','right','VerticalAlignment','top','FontSize',10);
            end
            dtiso = sprintf('%s-%s-%s %s TU',datestr(DH.tps(i),'yyyy'),datestr(DH.tps(i),'mm'),datestr(DH.tps(i),'dd'),datestr(DH.tps(i),'HH:MM:SS'));
            dtu = sprintf('%s %s %s %s %s TU',traduc(datestr(DH.tps(i),'ddd')),datestr(DH.tps(i),'dd'),traduc(datestr(DH.tps(i),'mmm')),datestr(DH.tps(i),'yyyy'),datestr(DH.tps(i),'HH:MM:SS'));
            dtl = sprintf('{\\bf%s %s %s %s � %s}',traduc(datestr(DH.tps(i)-4/24,'ddd')),datestr(DH.tps(i)-4/24,'dd'),traduc(datestr(DH.tps(i)-4/24,'mmm')),datestr(DH.tps(i)-4/24,'yyyy'),datestr(DH.tps(i)-4/24,'HH:MM'));
            text(.5,.7,{sprintf('Magnitude %1.1f, %05.2f�N, %05.2f�W, profondeur %1.0f km',DH.mag(i),DH.lat(i),-DH.lon(i),DH.dep(i)),dtu}, ...
                 'horizontalAlignment','center','VerticalAlignment','middle','FontSize',14,'FontWeight','bold');
            
            % Texte du communiqu� : param�tres � afficher
            s_qua = nommag{max([1,floor(DH.mag(i))])};
            s_mag = sprintf('%1.1f',DH.mag(i));
            s_vaz = boussole(atan2(DH.lat(i) - IC.lat(iv(1)),DH.lon(i) - IC.lon(iv(1))),1);
			epi = sqrt(((IC.lon(iv(1)) - DH.lon(i))*lonkm).^2 + ((IC.lat(iv(1)) - DH.lat(i))*latkm).^2);
            %epi = sqrt(vdhp(iv(1))^2 - DH.dep(i)^2);
            if epi < 1
                s_epi = 'moins de 1 km';
            else
                s_epi = sprintf('%1.0f km',epi);
            end
            s_gua = sprintf('%s',IC.nom{iv(1)});
            if DH.dep(i) < 1
                s_dep = 'moins de 1 km';
            else
                s_dep = sprintf('%1.0f km',DH.dep(i));
            end
			s_dhp = sprintf('%1.0f km',sqrt(epi^2 + DH.dep(i)^2));
	        s_typ = CS{3,DH.typ(i)};
            % NB: arrondi du PGA � 2 chiffres significatifs...
            og = 10^(floor(log10(vpga(iv(1)))) - 1);
            s_pga = sprintf('%1.0f mg',round(vpga(iv(1))/og)*og);
            if vmsk(1) > 1
                s_msk = sprintf('{\\bf%s � %s} (%s)',romanx(vmsk(1)-1),romanx(vmsk(1)),nommsk{vmsk(1)});
            else
                s_msk = sprintf('{\\bfI} (%s)',nommsk{1});
            end
            s_txt = {sprintf('Un %s (magnitude {\\bf%s} sur l''�chelle de Richter) a �t� enregistr� le %s',s_qua,s_mag,dtl), ...
                         sprintf('(heure locale) et identifi� d''origine {\\bf%s}. L''�picentre a �t� localis� �  {\\bf%s} %s de',s_typ,s_epi,s_vaz), ...
                         sprintf('{\\bf%s}, � %s de profondeur (soit une distance hypocentrale d''environ %s). Ce s�isme a pu',s_gua,s_dep,s_dhp), ...
                         sprintf('g�n�rer, dans les zones les plus proches de l''�picentre et sur certains types de sols, une acc�l�ration horizontale'), ...
                         sprintf('th�orique de {\\bf%s} (*), correspondant � une intensit� %s.',s_pga,s_msk)};
            text(0,0,s_txt,'horizontalAlignment','left','VerticalAlignment','bottom','FontSize',10);
            set(gca,'XLim',[0,1],'YLim',[0,1]), axis off
            
            % carte
            %pos0 = [.092,.08,.836,.646];
            pos0 = [.055,.126,.9,.600];
            h5 = axes('Position',pos0);
            pcolor(x,y,log10(pga)), shading flat, colormap(sjet), caxis(log10(pgamsk([1,10])))
            hold on
            pcontour(c_pta,[],gris), axis(xylim)
            h = dd2dms(gca,0);
            set(h,'FontSize',7)
            for ii = 2:length(pgamsk)
                [cs,h] = contour(x,y,pga,pgamsk([ii,ii]));
                set(h,'LineWidth',lwmsk(ii),'EdgeColor','k');
                if ~isempty(h)
                    hl = clabel(cs,h);
                    set(hl,'FontSize',8);
                end
            end
            % �picentre
            plot(DH.lon(i),DH.lat(i),'p','MarkerSize',10,'MarkerEdgeColor','k','MarkerFaceColor','w','LineWidth',1.5)
            
            % tableau des communes
            if ress
                ssl = [{'{\bfIntensit�s MSK suppos�es dans}';'{\bfles communes et acc�l�rations}';'{\bfth�oriques maximales :}';''};ss];
                if length(ss) < length(IC.lat)
                    ssl = [ssl;{'';'{\itnon ressenti dans les autres}';'{\itcommunes de la Guadeloupe.}'}];
                end
                h = rectangle('Position',[xylim(1)+.05,xylim(3)+.05,1.2,(length(ssl) + 1)*.08]);
                set(h,'FaceColor','w')
                text(xylim(1)+.1,xylim(3)+.1,ssl,'HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',8);
            end
            hold off
            
            % copyright
            text(xylim(2)+.03,xylim(3),txtb3,'Rotation',90,'HorizontalAlignment','left','VerticalAlignment','top','FontSize',7);
            
            % encart zoom zone �picentrale
            if epi < 20
                if epi > 8
                    depi = 20;  % largeur de l'encart (en km)
                    dsc = 10;   % �chelle des distances (en km)
                    fsv = 9;    % taille police noms villes
                    msv = 8;    % taille marqueurs villes
                else
                    depi = 10;
                    dsc = 5;
                    fsv = 11;
                    msv = 10;
                end
                ect = [DH.lon(i) + depi/lonkm*[-1,1],DH.lat(i) + depi/latkm*[-1,1]];
                % trac� du carr� sur la carte principale
                hold on
                plot(ect([1,2,2,1,1]),ect([3,3,4,4,3]),'w-','LineWidth',2);
                plot(ect([1,2,2,1,1]),ect([3,3,4,4,3]),'k-','LineWidth',.1);
                hold off
                w1 = .3;    % taille relative de l'encart (par rapport � la page)
                h6 = axes('Position',[pos0(1)+pos0(3)-(w1+.01),pos0(2)+pos0(4)-(w1+.01)*pps(3)/pps(4),w1,w1*pps(3)/pps(4)]);
                pcontour(c_pta,[],gris), axis(ect), set(gca,'FontSize',6,'XTick',[],'YTick',[])
                hold on
                plot(ect([1,2,2,1,1]),ect([3,3,4,4,3]),'k-','LineWidth',2);
                plot(DH.lon(i),DH.lat(i),'p','MarkerSize',20,'MarkerEdgeColor','k','MarkerFaceColor','w','LineWidth',2)
                k = find(IC.lon > ect(1) & IC.lon < ect(2) & IC.lat > ect(3) & IC.lat < ect(4));
                plot(IC.lon(k),IC.lat(k),'s','MarkerSize',msv,'MarkerEdgeColor','k','MarkerFaceColor','k')
                text(IC.lon(k),IC.lat(k)+.05*depi/latkm,IC.nom(k),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',fsv,'FontWeight','bold')
                xsc = ect(1) + .75*diff(ect(1:2));
                ysc = ect(3)+.03*diff(ect(3:4));
                plot(xsc+dsc*[-.5,.5]/lonkm,[ysc,ysc],'-k','LineWidth',2)
                text(xsc,ysc,sprintf('%d km',dsc),'HorizontalAlignment','center','VerticalAlignment','bottom','FontWeight','bold')
				for ii = 1:length(pgamsk)
					% nouvelle grille + serr�e
					[xz,yz] = meshgrid(linspace(ect(1),ect(2),100),linspace(ect(3),ect(4),100));
					dhpz = sqrt(((xz - DH.lon(i))*lonkm).^2 + ((yz - DH.lat(i))*latkm).^2 + DH.dep(i).^2);
					pgaz = efsite*1000*10.^(loi(1)*DH.mag(i) + loi(2)*dhpz - log10(dhpz) + loi(3));
					[cs,h] = contour(xz,yz,pgaz,pgamsk([ii,ii]));
					set(h,'LineWidth',.1,'EdgeColor','k');
					if ~isempty(h)
						hl = clabel(cs,h);
						set(hl,'FontSize',8);
					end
				end
                hold off
            end
            
            
            % Tableau des intensit�s
            h7 = axes('Position',[.03,.02,.95,.07]);
            sz = length(pgamsk) - 1;
            % �chelle de couleurs
            xx = linspace(2,sz+2,256)/(sz+2);
            pcolor(xx,repmat([0;1/4],[1,length(xx)]),repmat(linspace(log10(pgamsk(1)),log10(pgamsk(10)),length(xx)),[2,1]))
            shading flat, caxis(log10(pgamsk([1,10])))
            hold on
            % bordures
            plot([0,0,1,1,0],[0,1,1,0,0],'-k','LineWidth',2);
            for ii = 1:3
                plot([0,1],[ii,ii]/4,'-k','LineWidth',.1);
            end
            for ii = 2:(sz+1)
                plot([ii,ii]/(sz+2),[0,1],'-k','LineWidth',.1);
            end
            text(1/(sz+2),3.5/4,'{\bfPerception Humaine}','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7);
            for ii = 1:sz
                xx = (ii + 1.5)/(sz+2);
                text(xx,3.5/4,nomres{ii},'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7);
            end
            text(1/(sz+2),2.5/4,'{\bfD�g�ts Probables}','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7);
            for ii = 1:sz
                xx = (ii + 1.5)/(sz+2);
                text(xx,2.5/4,nomdeg{ii},'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7);
            end
            text(1/(sz+2),1.5/4,'{\bfAcc�l�rations (mg)}','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7);
            for ii = 1:sz
                xx = (ii + 1.5)/(sz+2);
                switch ii
                case 1 
                    ss = sprintf('< %g',pgamsk(ii+1));
                case sz
                    ss = sprintf('> %g',pgamsk(ii));
                otherwise
                    ss = sprintf('%g - %g',pgamsk([ii,ii+1]));
                end
                text(xx,1.5/4,ss,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7);
            end
            text(1/(sz+2),.5/4,'{\bfIntensit�s MSK}','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7);
            for ii = 1:sz
                xx = (ii + 1.5)/(sz+2);
                switch ii
                case sz
                    ss = sprintf('%s+',romanx(ii));
                otherwise
                    ss = romanx(ii);
                end
                text(xx,.5/4,ss,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',9);
            end
            text(0,0,{'(*) {\bfmg} = "milli g�" est une unit� d''acc�l�ration correspondant au milli�me de la pesanteur terrestre'}, ...
                'HorizontalAlignment','left','VerticalAlignment','top','FontSize',8);
            hold off
            set(gca,'XLim',[0,1],'YLim',[0,1]), axis off                    
            %h7 = axes('Position',[.05,0,.88,.05]);
            %text(0,0,{'(*) {\bfmg} = "milli g�" est une unit� d''acc�l�ration correspondant au milli�me de la pesanteur terrestre', ...
            %          '(**) D�finition de l''Echelle des Intensit�s: {\bfI} = non ressenti, {\bfII} = rarement ressenti, {\bfIII} = faiblement ressenti, {\bfIV} = largement ressenti,', ...
            %          '{\bfV} = secousse forte, {\bfVI} = d�g�ts l�gers, {\bfVII} = d�g�ts, {\bfVIII} = d�g�ts importants, {\bfIX} = destructions, {\bfX} = destructions importantes, ', ...
            %          '{\bfXI} = catastrophe, {\bfXII} = catastrophe g�n�ralis�e'}, ...
            %        'HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',8);
            %set(gca,'XLim',[0,1],'YLim',[0,1]), axis off

            % Image Postscript + envoi sur l'imprimante + lien symbolique "lasthypo.png"
            print('-dpsc',ftmp);
            disp(sprintf('Graphe: %s cr��.',ftmp));
            unix(sprintf('%s -sPAPERSIZE=a4 %s %s',X.PRGM_PS2PDF,ftmp,fgra));
            unix(sprintf('%s -resize 100x100 %s %s',X.PRGM_CONVERT,fgra,fjpg));
            disp(sprintf('Graphe: %s cr��.',fgra));
            if ~test
                unix(sprintf('lpr %s',ftmp));
                disp(sprintf('Graphe: %s imprim�.',ftmp));
				% envoi d'un e-mail � sismo...
				fid0 = fopen(mtmp,'wt');
				for ii = 1:length(s_txt)
					fprintf(fid0,[strrep(strrep(s_txt{ii},'{\bf',''),'}',''),' ']);
				end
				fprintf(fid0,'\n\nCommuniqu� complet sur ce s�isme :\n\nhttp://%s%s/Sismologie/B3/ressentis/%s/%s.pdf \n\n',X.RACINE_URL,X.WEB_RACINE_FTP,pam,fnam);
				fclose(fid0);
				unix(sprintf('cat %s >> %s',ftxt,mtmp));
				unix(sprintf('mail %s -s "S�isme %s MD=%s - B3=%s max � %s" < %s',X.SISMO_EMAIL,dtiso,s_mag,romanx(vmsk(1)),s_gua,mtmp));
				disp('E-mail envoy� � sismo...');
            end

            % Lien symbolique sur le dernier ressenti
            if ~test
                [s,w] = unix(sprintf('find %s/Sismologie/B3/ressentis/ -type f -name "*.pdf"|tail -1',X.RACINE_FTP));
                ss = sprintf('ln -sf %s %s',deblank(w),f3);
                unix(ss);
                disp(sprintf('Unix: %s',ss));
                [s,w] = unix(sprintf('find %s/Sismologie/B3/traites/ -type f -name "*.txt"|tail -1',X.RACINE_FTP));
                ss = sprintf('ln -sf %s %s',deblank(w),f2);
                unix(ss);
                disp(sprintf('Unix: %s',ss));
                ss = sprintf('%s -scale 71x105 %s %s',X.PRGM_CONVERT,f3,f4);
                unix(ss);
                disp(sprintf('Unix: %s',ss));
            end
        end
    end
end
close

timelog(rcode,2);
