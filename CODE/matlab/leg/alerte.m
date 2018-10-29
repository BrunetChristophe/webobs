function alerte(s,a,t,f)
%ALERTE Envoie une alerte par mail
%	ALERTE(S) envoie un mail � l'alias local "alerte2", avec la chaine S dans le
%	sujet (max 150 caract�res).
%	ALERTE(S,A,T) envoie � l'adresse e-mail A, avec le corps de texte contenu
%	dans le fichier T.
%	ALERTE(S,A,T,F) ajoute le fichier F en pi�ce attach�e.
%
%	ALERTE utilise la commande externe MUTT.
%
%	Auteurs: Fran�ois Beauducel, Christian Ant�nor-Habazac, Alexis Bosson
%	Cr��: 2004-10-01
%	Modifi�: 2009-09-20

X = readconf;

if nargin < 2
	% Utilisation de l'adresse e-mail d'alerte SMS de WebOBS (alerte2)
	a = X.SMS_ALERTE_EMAIL;
	% Envoi de l'alerte � Shiva (Stupide Humano�de d'Interpr�tation Vocale des Alertes)
	unix(sprintf('%s/alerte_shiva "%s"',X.RACINE_TOOLS_SHELLS,s));
	% Envoi de l'alerte par SMS aux t�l�phones d�finis
	unix(sprintf('%s/alerte_sms_webobs "%s"',X.RACINE_TOOLS_SHELLS,s));
end
if nargin < 3
	% Corps du mail vide
	t = '/dev/null';
end
if nargin < 4
	% mail normal
	unix(sprintf('mutt -F %s/webobs.muttrc -s "%s" %s < %s',X.RACINE_FICHIERS_CONFIGURATION,s,a,t));
else
	% mail avec pi�ce jointe
	unix(sprintf('mutt -F %s/webobs.muttrc -s "%s" -a %s %s < %s',X.RACINE_FICHIERS_CONFIGURATION,s,f,a,t));
end
disp(sprintf('Email: "%s" sent to %s.',s,a));
