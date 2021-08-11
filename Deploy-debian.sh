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
  ip_du_serveur=$(hostname -i)
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput bold; tput setaf 7; echo "                      => L'adresse IP du serveur est $ip_du_serveur.                     "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"


  echo "
 
Server   : $name_server
IP       : $ip_du_serveur
Provider : $name_provider
 
  " > /etc/motd
  
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
  tput setaf 6; echo "Installation de Portainer.................................................... E$  Install-Portainer
  tput setaf 7; echo "Installation de Portainer.................................................... O$
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
