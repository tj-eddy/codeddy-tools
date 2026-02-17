#!/bin/bash
#
# Script d'installation de Docker et DDEV pour Linux Mint
# Ce script installe Docker Engine et DDEV avec toutes les dépendances nécessaires
#

set -e  # Arrêter en cas d'erreur

echo "======================================"
echo "Installation de Docker et DDEV"
echo "======================================"
echo ""

# Vérifier si le script est exécuté en tant que root
if [ "$EUID" -eq 0 ]; then 
   echo "⚠️  Ne pas exécuter ce script en tant que root/sudo"
   echo "Le script demandera sudo uniquement quand nécessaire"
   exit 1
fi

# Mise à jour du système
echo "📦 Mise à jour du système..."
sudo apt-get update
sudo apt-get upgrade -y

# Installation des dépendances
echo ""
echo "📦 Installation des dépendances..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Désinstaller les anciennes versions de Docker si présentes
echo ""
echo "🧹 Nettoyage des anciennes versions de Docker..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Ajouter la clé GPG officielle de Docker
echo ""
echo "🔑 Ajout de la clé GPG de Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Ajouter le dépôt Docker
echo ""
echo "📚 Ajout du dépôt Docker..."
# Linux Mint est basé sur Ubuntu, utiliser la version Ubuntu correspondante
UBUNTU_CODENAME=$(cat /etc/upstream-release/lsb-release 2>/dev/null | grep CODENAME | cut -d= -f2 || echo "jammy")
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Mise à jour et installation de Docker
echo ""
echo "🐳 Installation de Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Ajouter l'utilisateur au groupe docker
echo ""
echo "👤 Ajout de l'utilisateur au groupe docker..."
sudo usermod -aG docker $USER

# Démarrer et activer Docker
echo ""
echo "🚀 Démarrage de Docker..."
sudo systemctl start docker
sudo systemctl enable docker

# Vérifier l'installation de Docker
echo ""
echo "✅ Vérification de Docker..."
sudo docker --version
sudo docker compose version

# Installation de DDEV
echo ""
echo "======================================"
echo "Installation de DDEV"
echo "======================================"
echo ""

# Télécharger et installer DDEV
echo "📥 Téléchargement de DDEV..."
curl -fsSL https://ddev.com/install.sh | bash

# Vérifier l'installation de DDEV
echo ""
echo "✅ Vérification de DDEV..."
ddev version

# Configuration de mkcert pour HTTPS
echo ""
echo "🔒 Configuration de mkcert pour HTTPS..."
mkcert -install || echo "⚠️  Erreur lors de l'installation de mkcert (non critique)"

echo ""
echo "======================================"
echo "✅ Installation terminée avec succès!"
echo "======================================"
echo ""
echo "⚠️  IMPORTANT: Vous devez vous déconnecter et vous reconnecter"
echo "   (ou redémarrer) pour que les changements de groupe docker"
echo "   prennent effet."
echo ""
echo "Pour vérifier que tout fonctionne, après reconnexion:"
echo "  docker --version"
echo "  docker compose version"
echo "  ddev version"
echo ""
echo "Pour tester Docker sans sudo:"
echo "  docker run hello-world"
echo ""
