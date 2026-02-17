#!/bin/bash
#
# Script d'installation de WordPress dans DDEV
# Ce script crée un projet DDEV et installe WordPress automatiquement
#

set -e

echo "======================================"
echo "Installation de WordPress avec DDEV"
echo "======================================"
echo ""

# Demander le nom du projet
read -p "Nom du projet WordPress (par défaut: wordpress): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-wordpress}

# Demander les informations du site
read -p "Titre du site (par défaut: Mon Site WordPress): " SITE_TITLE
SITE_TITLE=${SITE_TITLE:-"Mon Site WordPress"}

read -p "Nom d'utilisateur admin (par défaut: admin): " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -p "Email admin (par défaut: admin@example.com): " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-"admin@example.com"}

read -sp "Mot de passe admin (par défaut: admin123): " ADMIN_PASSWORD
echo ""
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin123}

# Créer le dossier du projet
echo ""
echo "📁 Création du dossier du projet: $PROJECT_NAME"
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Configurer DDEV pour WordPress
echo ""
echo "⚙️  Configuration de DDEV..."
ddev config --project-type=wordpress --php-version=8.1 --docroot=wordpress --project-name=$PROJECT_NAME

# Démarrer DDEV
echo ""
echo "🚀 Démarrage de DDEV..."
ddev start

# Télécharger WP-CLI (si pas déjà présent)
echo ""
echo "📥 Installation de WP-CLI..."
ddev composer global require wp-cli/wp-cli-bundle || true

# Télécharger WordPress
echo ""
echo "📥 Téléchargement de WordPress..."
ddev exec "wp core download --locale=fr_FR --path=wordpress"

# Créer le fichier wp-config.php
echo ""
echo "⚙️  Configuration de WordPress..."
ddev exec "wp config create --dbname=db --dbuser=db --dbpass=db --dbhost=db --path=wordpress --locale=fr_FR"

# Installer WordPress
echo ""
echo "🔧 Installation de WordPress..."
SITE_URL="https://$PROJECT_NAME.ddev.site"
ddev exec "wp core install --url='$SITE_URL' --title='$SITE_TITLE' --admin_user='$ADMIN_USER' --admin_password='$ADMIN_PASSWORD' --admin_email='$ADMIN_EMAIL' --path=wordpress"

# Installer et activer le thème français
echo ""
echo "🎨 Installation du thème par défaut..."
ddev exec "wp theme install twentytwentyfour --activate --path=wordpress"

# Supprimer les plugins et thèmes par défaut inutiles
echo ""
echo "🧹 Nettoyage des plugins et thèmes par défaut..."
ddev exec "wp plugin delete hello --path=wordpress" || true
ddev exec "wp plugin delete akismet --path=wordpress" || true

# Configurer les permaliens
echo ""
echo "🔗 Configuration des permaliens..."
ddev exec "wp rewrite structure '/%postname%/' --path=wordpress"
ddev exec "wp rewrite flush --path=wordpress"

# Définir les permissions
echo ""
echo "🔐 Configuration des permissions..."
ddev exec "chmod -R 755 wordpress"
ddev exec "chmod -R 777 wordpress/wp-content/uploads"

echo ""
echo "======================================"
echo "✅ WordPress installé avec succès!"
echo "======================================"
echo ""
echo "🌐 URL du site: $SITE_URL"
echo "🔐 URL admin: $SITE_URL/wp-admin"
echo ""
echo "📋 Informations de connexion:"
echo "   - Utilisateur: $ADMIN_USER"
echo "   - Mot de passe: $ADMIN_PASSWORD"
echo "   - Email: $ADMIN_EMAIL"
echo ""
echo "🚀 Pour ouvrir le site:"
echo "   ddev launch"
echo ""
echo "🚀 Pour ouvrir l'admin:"
echo "   ddev launch /wp-admin"
echo ""
echo "📝 Commandes WP-CLI utiles:"
echo "   ddev exec 'wp plugin list --path=wordpress'"
echo "   ddev exec 'wp theme list --path=wordpress'"
echo "   ddev exec 'wp user list --path=wordpress'"
echo "   ddev exec 'wp plugin install woocommerce --activate --path=wordpress'"
echo ""
echo "📝 Commandes DDEV utiles:"
echo "   ddev start       - Démarrer le projet"
echo "   ddev stop        - Arrêter le projet"
echo "   ddev restart     - Redémarrer le projet"
echo "   ddev ssh         - Se connecter au conteneur"
echo "   ddev logs        - Voir les logs"
echo "   ddev describe    - Voir les informations du projet"
echo ""
