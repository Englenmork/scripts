#!/bin/bash
####################################################
#                                                  #
# Configuration automatique de Debian par Yann     #
#                                                  #
####################################################


function Verif-System {
  user=$(whoami)

  if [ $(whoami) != "root" ]
    then
    tput setaf 5; echo "ERREUR : Veuillez exécuter le script en tant que Root !"
    exit
  fi

  if [[ $(arch) != *"64" ]]
    then
    tput setaf 5; echo "ERREUR : Veuillez installer une version x64 !"
    exit
  fi
  
}

# Changement des sources APT
#version=$(grep "VERSION=" /etc/os-release |awk -F= {' print $2'}|sed s/\"//g |sed s/[0-9]//g | sed s/\)$//g |sed s/\(//g)
#function Change-Source {
#  echo "deb http://debian.mirrors.ovh.net/debian/ $version main contrib non-free
#  deb-src http://debian.mirrors.ovh.net/debian/ $version main contrib non-free
#  
#  deb http://security.debian.org/ $version/updates main contrib non-free
#  deb-src http://security.debian.org/ $version/updates main contrib non-free
#  
#  # $version-updates, previously known as 'volatile'
#  deb http://debian.mirrors.ovh.net/debian/ $version-updates main contrib non-free
#  deb-src http://debian.mirrors.ovh.net/debian/ $version-updates main contrib non-free" > /etc/apt/sources.list
#  echo 'deb http://deb.debian.org/debian $version-backports main' > \
#   /etc/apt/sources.list.d/backports.list
#}


# Mise à jours des paquets
function Install-PaquetsEssentiels {
  apt update && apt upgrade -y
  apt install -y sudo 
  apt install -y chpasswd
  apt install -y openssh-server
  apt install -y cockpit
  apt install -y neofetch
  apt install -y curl
  apt install -y fail2ban
  apt install -y neofetch
  apt install -y htop
  apt install -y apt-transport-https
  }

# Installation des dépendances et de docker
function Install-Docker {
  tput setaf 2; apt-get install -y apt-transport-https ca-certificates gnupg2 software-properties-common
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
  apt-get update
  apt-get -y install docker-ce docker-compose
  systemctl enable docker
  systemctl start docker
}

#Configuration et installation de Portainer
function Install-Portainer {

docker volume create portainer_data

docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
}

#Configuration et installation de LXD
function Install-Lxd {
  apt-get -y install snapd
  apt-get -y install core
  snap install core
  snap install lxd
}

#Installation de Webmin
function Install-Webmin {
  echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
  apt install -y gnupg2
  wget https://download.webmin.com/jcameron-key.asc
  apt-key add jcameron-key.asc
  apt update
  apt install -y webmin
}

function Change-Password {
  tput setaf 6; echo "root:$password_root" | chpasswd
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput setaf 7; echo "                                => Mot de passe de Root a été changé.                               "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput setaf 2; adduser --quiet --disabled-password --shell /bin/bash --home /home/$name_user --gecos "User" $name_user
  tput setaf 2; echo "$name_user:$password_user" | chpasswd
  tput setaf 2; adduser $name_user sudo
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput bold; tput setaf 7; echo "                         => L'utilisateur $name_user a été créé.                         "
  tput bold; tput setaf 7; echo "                         => $name_user fait parti du groupe sudo.                        "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
}

# Changement du port SSH
function Change-SSHPort {
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config_backup

  for file in /etc/ssh/sshd_config
  do
    echo "Traitement de $file ..."
    sed -i -e "s/#Port 22/Port $ssh_port/" "$file"
  done  
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput setaf 7; echo "                                 => Port SSH remplacé par $ssh_port.                                "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"

}

# Changement du motd
function Change-MOTD {
  ip_du_serveur=$(hostname -I)
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput bold; tput setaf 7; echo "                      => L'adresse IP du serveur est $ip_du_serveur.                     "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  apt install -y figlet
  cd /etc
  mkdir /update-motd.d && chmod 644 /update-motd.d
  cd /update-motd.d
  rm 10-uname
  touch colors
  echo 'NONE="\033[m"
WHITE="\033[1;37m"
GREEN="\033[1;32m"
RED="\033[0;32;31m"
YELLOW="\033[1;33m"
BLUE="\033[34m"
CYAN="\033[36m"
LIGHT_GREEN="\033[1;32m"
LIGHT_RED="\033[1;31m" ' > colors
  touch 00-hostname
  echo '#!/bin/sh

. /etc/update-motd.d/colors

printf "\n"$LIGHT_RED
figlet "  "$(hostname -s)
printf $NONE
printf "\n" ' > 00-hostname
  touch 10-banner
  echo '#!/bin/bash

. /etc/update-motd.d/colors

[ -r /etc/update-motd.d/lsb-release ] && . /etc/update-motd.d/lsb-release

if [ -z "$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
    # Fall back to using the very slow lsb_release utility
    DISTRIB_DESCRIPTION=$(lsb_release -s -d)
fi
' > 10-banner
echo "re='(.*\()(.*)(\).*)'
" >> 10-banner
echo 'if [[ $DISTRIB_DESCRIPTION =~ $re ]]; then
    DISTRIB_DESCRIPTION=$(printf "%s%s%s%s%s" "${BASH_REMATCH[1]}" "${YELLOW}" "${BASH_REMATCH[2]}" "${NONE}" "${BASH_REMATCH[3]}")
fi
' >> 10-banner

echo 'echo -e "  "$DISTRIB_DESCRIPTION "(kernel "$(uname -r)")\n"

# Update the information for next time
printf "DISTRIB_DESCRIPTION=\"%s\"" "$(lsb_release -s -d)" > /etc/update-motd.d/lsb-release &' >> 10-banner
  touch 20-sysinfo
  echo '#!/bin/bash' > 20-sysinfo
  echo -e 'proc=`(echo $(more /proc/cpuinfo | grep processor | wc -l ) "x" $(more /proc/cpuinfo | grep 'model name' | uniq |awk -F":"  '{print $2}') )`'echoq >> 20-sysinfo
  echo 'memfree=`cat /proc/meminfo | grep MemFree | awk {'print $2'}`' >> 20-sysinfo
  echo 'memtotal=`cat /proc/meminfo | grep MemTotal | awk {'print $2'}`' >> 20-sysinfo
  
  echo 'uptime=`uptime -p`
addrip=`hostname -I | cut -d " " -f1`
# Récupérer le loadavg
read one five fifteen rest < /proc/loadavg

# Affichage des variables
printf "  Processeur : $proc"
printf "\n"
printf "  Charge CPU : $one (1min) / $five (5min) / $fifteen (15min)"
printf "\n"
printf "  Adresse IP : $addrip"
printf "\n"
printf "  RAM : $(($memfree/1024))MB libres / $(($memtotal/1024))MB"
printf "\n"
printf "  Uptime : $uptime"
printf "\n"
printf "\n" ' >> 20-sysinfo

  chmod 755 00-hostname
  chmod 755 10-banner
  chmod 755 20-sysinfo
  rm /etc/motd
  ln -s /var/run/motd /etc/motd
}

#-----------------------------------------------------------------------------------------------------------------------------------
install_portainer = "n"
clear
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput setaf 7; echo "                                   Script d'installation de Debian                                  "
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"

tput setaf 6; read -p "Souhaitez vous créer les utilisateurs ? (y/n)  " create_user
if [ $create_user = "y" ]
  then
    tput setaf 6; read -p "===>     Entrez le mot de passe pour Root : " password_root
    tput setaf 6; read -p "===>     Entrez un nom d'utilisateur : " name_user
    tput setaf 6; read -p "===>     Entrez le mot de passe pour l'utilisateur $name_user : " password_user
fi
echo ""

tput setaf 6; read -p "Souhaitez vous changer le port SSH ? (recommandé) (y/n)  " change_sshport
if [ $change_sshport = "y" ]
  then
    tput setaf 6; read -p "===>     Entrez port que vous souhaitez : " ssh_port
fi
echo ""

tput setaf 6; read -p "Souhaitez vous changer le MOTD ? (y/n)  " change_motd
if [ $change_motd = "y" ]
  then
  tput setaf 6; read -p "===>     Entrez le nom du serveur : " name_server
  tput setaf 6; read -p "===>     Entrez le nom de l'hébergeur : " name_provider
fi
echo ""

tput setaf 6; read -p "Souhaitez vous installer Docker ? (y/n)  " install_docker
if [ $install_docker = "y" ]
  then
  echo ""
  tput setaf 6; read -p "Souhaitez vous installer Portainer ? (y/n)  " install_portainer
  if [ $install_portainer = "y" ]
    then
    tput setaf 3; echo ""
  fi
fi
echo ""

tput setaf 6; read -p "Souhaitez vous installer LXD ? (y/n)  " install_lxd
if [ $install_lxd = "y" ]
  then
    tput setaf 3; echo ""
fi
echo ""

tput setaf 6; read -p "Souhaitez vous installer Webmin ? (y/n)  " install_webmin
if [ $install_webmin = "y" ]
  then
    tput setaf 3; echo ""
fi
echo ""
echo ""
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput setaf 7; echo "                                           Début du script                                          "
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
echo ""
echo ""


tput setaf 6; echo "Vérification du système ................................................................... En cours"
Verif-System
tput setaf 7; echo "Vérification du système ................................................................... OK"
echo ""


#tput setaf 6; echo "Configuration des sources ................................................................. En cours"
#Change-Source
#tput setaf 7; echo "Configuration des sources ................................................................. OK"
#echo ""

tput setaf 6; echo "Installation des paquets essentiels........................................................ En cours"
Install-PaquetsEssentiels
tput setaf 7; echo "Installation des paquets essentiels........................................................ OK"
echo ""
echo ""

if [ $install_docker = "y" ]
  then
  tput setaf 6; echo "Installation de Docker..................................................................... En cours"
  Install-Docker
  tput setaf 7; echo "Installation de Docker..................................................................... OK"
  if [ $install_portainer = "y" ]
  then
  tput setaf 6; echo "Installation de Portainer..................................................................... En Cours"
  Install-Portainer
  tput setaf 7; echo "Installation de Portainer.................................................... OK"
  fi
fi

echo ""
echo ""
if [ $install_lxd = "y" ]
  then
  tput setaf 6; echo "Installation de Lxd.................................................... En cours"
  Install-Lxd
  tput setaf 7; echo "Installation de Lxd.................................................... OK"
fi
echo ""
echo ""
if [ $install_webmin = "y" ]
  then
  tput setaf 6; echo "Installation de Webmin.................................................... En cours"
  Install-Webmin
  tput setaf 7; echo "Installation de Webmin.................................................... OK"
fi
echo ""
echo ""
if [ $create_user = "y" ]
  then
  tput setaf 6; echo "Création des utilisateurs et changement des mots de passe.................................. En cours"
  Change-Password
  tput setaf 7; echo "Création des utilisateurs et changement des mots de passe.................................. OK"
fi

echo ""
echo ""
if [ $change_sshport = "y" ]
  then
  tput setaf 6; echo "Changement du port SSH.................................................................... En cours"
  Change-SSHPort
  tput setaf 7; echo "Changement du port SSH.................................................................... OK"
fi

echo ""
echo ""
if [ $change_motd = "y" ] 
  then
  tput setaf 6; echo "Changement du MOTD....................................................................... En cours"
  Change-MOTD
  tput setaf 7; echo "Changement du MOTD....................................................................... OK"
fi

echo ""
echo ""
if [ $install_portainer = "y" ]
  then
  echo ""
  echo ""
  tput bold; tput setaf 7; echo "LISTES DES CONTAINERS EN COURS : "
  tput setaf 3; echo ""
  docker container ls
fi

echo ""
echo ""
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput bold; tput setaf 7; echo "                               => PREPARATION TERMINEE <=                                "
tput setaf 7; echo ""

tput bold; tput setaf 7; echo "                                Veuillez vous reconnecter                                "
if [ $change_sshport = "y" ]
  then
  tput bold; tput setaf 7; echo "                             Votre nouveau port SSH : $ssh_port                        "
fi
tput setaf 7; echo ""
tput bold; tput setaf 6; echo "                                       By Yann                                           "
tput bold; tput setaf 6; echo "                               veratyr.fr / prolinux.fr                                  "
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput setaf 2; echo ""

sleep 5
# Redémarrage du service sshd
service ssh restart
