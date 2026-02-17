#!/bin/bash
#
# Script d'installation de PrestaShop dans DDEV
# Ce script crée un projet DDEV et installe PrestaShop
#

set -e

echo "======================================"
echo "Installation de PrestaShop avec DDEV"
echo "======================================"
echo ""

# Demander le nom du projet
read -p "Nom du projet PrestaShop (par défaut: prestashop): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-prestashop}

# Demander la version de PrestaShop
echo ""
echo "Versions disponibles:"
echo "  1) PrestaShop 9.0.3  (derniere stable 9.x - PHP 8.1+)"
echo "  2) PrestaShop 8.2.4  (derniere stable 8.2 - PHP 8.1+)"
echo "  3) PrestaShop 8.1.7  (derniere stable 8.1 - PHP 8.1+)"
echo "  4) PrestaShop 1.7.8.11 (derniere stable 1.7 - PHP 7.1 a 7.4)"
read -p "Choisir la version (1-4, defaut: 1): " VERSION_CHOICE
VERSION_CHOICE=${VERSION_CHOICE:-1}

case "$VERSION_CHOICE" in
    2)
        PRESTASHOP_VERSION="8.2.4"
        PHP_VERSION="8.1"
        ;;
    3)
        PRESTASHOP_VERSION="8.1.7"
        PHP_VERSION="8.1"
        ;;
    4)
        PRESTASHOP_VERSION="1.7.8.11"
        PHP_VERSION="7.4"
        ;;
    *)
        PRESTASHOP_VERSION="9.0.3"
        PHP_VERSION="8.1"
        ;;
esac

# Créer le dossier du projet
echo ""
echo "📁 Création du dossier du projet: $PROJECT_NAME"
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Configurer DDEV
echo ""
echo "⚙️  Configuration de DDEV..."
ddev config --project-type=php --php-version=$PHP_VERSION --docroot=public --project-name=$PROJECT_NAME

# Démarrer DDEV
echo ""
echo "🚀 Démarrage de DDEV..."
ddev start

# Télécharger PrestaShop
echo ""
echo "📥 Téléchargement de PrestaShop $PRESTASHOP_VERSION..."
ddev exec "curl -L https://github.com/PrestaShop/PrestaShop/releases/download/${PRESTASHOP_VERSION}/prestashop_${PRESTASHOP_VERSION}.zip -o prestashop.zip"

# Créer le dossier public s'il n'existe pas
ddev exec "mkdir -p public"

# Extraire PrestaShop
echo ""
echo "📦 Extraction de PrestaShop..."
ddev exec "unzip -o -q prestashop.zip -d public/"
ddev exec "cd public && unzip -o -q prestashop.zip"
ddev exec "rm -f prestashop.zip"
ddev exec "rm -f public/prestashop.zip"

# Définir les permissions
echo ""
echo "🔐 Configuration des permissions..."
ddev exec "cd public && mkdir -p var config download img log mails modules themes translations upload"
ddev exec "chmod -R 777 public/var public/config public/download public/img public/log public/mails public/modules public/themes public/translations public/upload"

# Créer la base de données
echo ""
echo "🗄️  Configuration de la base de données..."
ddev exec "mysql -e 'DROP DATABASE IF EXISTS db; CREATE DATABASE db;'"

echo ""
echo "======================================"
echo "✅ PrestaShop est prêt pour l'installation!"
echo "======================================"
echo ""
echo "🌐 URL du site: https://$PROJECT_NAME.ddev.site"
echo ""
echo "📋 Informations pour l'installation web:"
echo "   - URL de la base de données: db"
echo "   - Nom de la base: db"
echo "   - Utilisateur: db"
echo "   - Mot de passe: db"
echo "   - Port: 3306"
echo ""
echo "🚀 Pour ouvrir le site:"
echo "   ddev launch"
echo ""
echo "ℹ️  Suivez l'assistant d'installation web pour terminer."
echo "   Après l'installation, supprimez le dossier 'install' :"
echo "   ddev exec 'rm -rf public/install'"
echo ""
echo "📝 Commandes utiles:"
echo "   ddev start       - Démarrer le projet"
echo "   ddev stop        - Arrêter le projet"
echo "   ddev restart     - Redémarrer le projet"
echo "   ddev ssh         - Se connecter au conteneur"
echo "   ddev logs        - Voir les logs"
echo "   ddev describe    - Voir les informations du projet"
echo ""
