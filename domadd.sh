#!/bin/bash
read -p "Nouveau domaine (ex : homeCA) : " domaine
echo ' '
mkdir /usr/local/share/ca-certificates/$domaine
cd /usr/local/share/ca-certificates/$domaine/
openssl genrsa -des3 -out $domaine.key 2048
openssl req -x509 -new -nodes -key $domaine.key -sha256 -days 10000 -out $domaine.pem
openssl x509 -in $domaine.pem -inform PEM -out $domaine.crt
echo 'Creation du domaine ok'
echo ' '
read -p 'Voulez vous copier le certificat dans un dossier ? (y/n) ' copie
	if [ $copie = "y" ]
		then 
			echo ' '
			read -p "Ou voulez vous copier le certificat ? " dossier
			cp $domaine.key $dossier
			cp $domaine.pem $dossier
			cp $domaine.crt $dossier
			echo 'Copie du certificat dans ok'
		else
			echo 'OK pas de copie'
	fi
