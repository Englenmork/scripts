#!/bin/bash

read -p "Domaine (ex: homeCA) : " domaine

read -p "Nouveau certificat (ex: home.lan) : " certadd

cd /usr/local/share/ca-certificates/$domaine/

openssl genrsa -out $certadd.key 2048

openssl req -new -key $certadd.key -out $certadd.csr

touch $certadd.ext

echo "authorityKeyIdentifier=keyid,issuer" > $certadd.ext
echo "basicConstraints=CA:FALSE" >> $certadd.ext
echo "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment" >> $certadd.ext
echo "subjectAltName = @alt_names" >> $certadd.ext
echo "[alt_names]" >> $certadd.ext
echo "DNS.1 = $certadd" >> $certadd.ext

openssl x509 -req -in $certadd.csr -CA $domaine.pem -CAkey $domaine.key -CAcreateserial -out $certadd.crt -days 10000 -sha256 -extfile $certadd.ext

echo ' '

read -p 'Voulez vous copier le certificat dans un dossier ? (y/n) ' copie
        if [ $copie = "y" ]
                then
                        echo ' '
                        read -p "Ou voulez vous copier le certificat ? " dossier
                        cp $certadd.key $dossier/
                        cp $certadd.ext $dossier/
                        cp $certadd.crt $dossier/
			                  cp $certadd.csr $dossier/ 
                        echo "Copie du certificat dans $dossier ok "
                else
                        echo 'OK pas de copie'
        fi
