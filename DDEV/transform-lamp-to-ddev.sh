#!/bin/bash
#
# Script pour transformer un projet LAMP existant en projet DDEV
# Ce script migre une application LAMP vers DDEV
#

set -e

echo "======================================"
echo "Transformation LAMP vers DDEV"
echo "======================================"
echo ""

# Vérifier que nous sommes dans un dossier
if [ ! -d "$(pwd)" ]; then
    echo "❌ Erreur: Impossible de déterminer le répertoire actuel"
    exit 1
fi

# Demander les informations du projet
echo "📋 Ce script va transformer votre projet LAMP en projet DDEV"
echo "   Assurez-vous d'être dans le dossier racine de votre projet"
echo ""
read -p "Êtes-vous dans le bon dossier? ($(pwd)) [O/n]: " CONFIRM
CONFIRM=${CONFIRM:-O}

if [ "$CONFIRM" != "O" ] && [ "$CONFIRM" != "o" ]; then
    echo "❌ Annulation"
    exit 1
fi

# Détecter le type de projet
echo ""
echo "🔍 Détection du type de projet..."

PROJECT_TYPE="php"
DOCROOT="."
PHP_VERSION="8.1"

# Détection WordPress
if [ -f "wp-config.php" ] || [ -f "wp-settings.php" ]; then
    PROJECT_TYPE="wordpress"
    DOCROOT="."
    echo "✅ Projet WordPress détecté"
fi

# Détection Symfony
if [ -f "symfony.lock" ] || [ -d "src/Controller" ]; then
    PROJECT_TYPE="php"
    DOCROOT="public"
    PHP_VERSION="8.2"
    echo "✅ Projet Symfony détecté"
fi

# Détection PrestaShop
if [ -d "classes" ] && [ -d "controllers" ] && [ -f "config/config.inc.php" ]; then
    PROJECT_TYPE="php"
    DOCROOT="."
    PHP_VERSION="8.1"
    echo "✅ Projet PrestaShop détecté"
fi

# Détection Laravel
if [ -f "artisan" ]; then
    PROJECT_TYPE="laravel"
    DOCROOT="public"
    PHP_VERSION="8.2"
    echo "✅ Projet Laravel détecté"
fi

# Détection Drupal
if [ -f "core/lib/Drupal.php" ]; then
    PROJECT_TYPE="drupal"
    DOCROOT="web"
    PHP_VERSION="8.1"
    echo "✅ Projet Drupal détecté"
fi

# Si pas de détection, demander
if [ "$PROJECT_TYPE" = "php" ] && [ "$DOCROOT" = "." ]; then
    echo "⚠️  Type de projet non détecté automatiquement"
    echo ""
    echo "Types de projets disponibles:"
    echo "  1) WordPress"
    echo "  2) PrestaShop"
    echo "  3) Symfony"
    echo "  4) Laravel"
    echo "  5) Drupal"
    echo "  6) PHP générique"
    read -p "Choisir le type (1-6): " TYPE_CHOICE
    
    case $TYPE_CHOICE in
        1) PROJECT_TYPE="wordpress"; DOCROOT="." ;;
        2) PROJECT_TYPE="php"; DOCROOT="." ;;
        3) PROJECT_TYPE="php"; DOCROOT="public"; PHP_VERSION="8.2" ;;
        4) PROJECT_TYPE="laravel"; DOCROOT="public"; PHP_VERSION="8.2" ;;
        5) PROJECT_TYPE="drupal"; DOCROOT="web" ;;
        6) PROJECT_TYPE="php"; read -p "Dossier racine web (par défaut: .): " DOCROOT; DOCROOT=${DOCROOT:-.} ;;
    esac
fi

# Demander le nom du projet
PROJECT_NAME=$(basename $(pwd))
read -p "Nom du projet DDEV (par défaut: $PROJECT_NAME): " NEW_PROJECT_NAME
PROJECT_NAME=${NEW_PROJECT_NAME:-$PROJECT_NAME}

# Demander la version PHP
read -p "Version PHP (par défaut: $PHP_VERSION): " NEW_PHP_VERSION
PHP_VERSION=${NEW_PHP_VERSION:-$PHP_VERSION}

# Sauvegarder la configuration de la base de données existante
echo ""
echo "🗄️  Configuration de la base de données"
echo ""
read -p "Nom de l'hôte MySQL actuel (par défaut: localhost): " OLD_DB_HOST
OLD_DB_HOST=${OLD_DB_HOST:-localhost}

read -p "Nom de la base de données: " OLD_DB_NAME
read -p "Utilisateur MySQL: " OLD_DB_USER
read -sp "Mot de passe MySQL: " OLD_DB_PASS
echo ""

read -p "Voulez-vous importer la base de données existante? [O/n]: " IMPORT_DB
IMPORT_DB=${IMPORT_DB:-O}

# Créer une sauvegarde avant de continuer
echo ""
echo "💾 Création d'une sauvegarde..."
BACKUP_DIR="backup-lamp-$(date +%Y%m%d_%H%M%S)"
mkdir -p ../$BACKUP_DIR
cp -r . ../$BACKUP_DIR/ 2>/dev/null || echo "⚠️  Quelques fichiers n'ont pas pu être sauvegardés"
echo "✅ Sauvegarde créée dans ../$BACKUP_DIR"

# Exporter la base de données si demandé
if [ "$IMPORT_DB" = "O" ] || [ "$IMPORT_DB" = "o" ]; then
    echo ""
    echo "📤 Export de la base de données..."
    mysqldump -h "$OLD_DB_HOST" -u "$OLD_DB_USER" -p"$OLD_DB_PASS" "$OLD_DB_NAME" > database_backup.sql || {
        echo "⚠️  Erreur lors de l'export. Continuez-vous sans importer la DB? [O/n]"
        read CONTINUE
        if [ "$CONTINUE" != "O" ] && [ "$CONTINUE" != "o" ]; then
            exit 1
        fi
        IMPORT_DB="n"
    }
fi

# Configurer DDEV
echo ""
echo "⚙️  Configuration de DDEV..."
ddev config --project-type=$PROJECT_TYPE --php-version=$PHP_VERSION --docroot=$DOCROOT --project-name=$PROJECT_NAME

# Démarrer DDEV
echo ""
echo "🚀 Démarrage de DDEV..."
ddev start

# Importer la base de données
if [ "$IMPORT_DB" = "O" ] || [ "$IMPORT_DB" = "o" ]; then
    if [ -f "database_backup.sql" ]; then
        echo ""
        echo "📥 Import de la base de données dans DDEV..."
        ddev import-db --file=database_backup.sql
        echo "✅ Base de données importée"
    fi
fi

# Mettre à jour les fichiers de configuration selon le type de projet
echo ""
echo "📝 Mise à jour de la configuration..."

case $PROJECT_TYPE in
    "wordpress")
        if [ -f "wp-config.php" ]; then
            echo "Mise à jour de wp-config.php..."
            # Créer un wp-config-ddev.php
            cat > wp-config-ddev.php <<'EOF'
<?php
// Configuration DDEV pour WordPress
define('DB_NAME', 'db');
define('DB_USER', 'db');
define('DB_PASSWORD', 'db');
define('DB_HOST', 'db');

// Inclure le wp-config.php original pour le reste
define('WP_CONTENT_DIR', dirname(__FILE__) . '/wp-content');
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
EOF
            echo "✅ Créé wp-config-ddev.php (à fusionner avec wp-config.php)"
        fi
        ;;
        
    "php")
        if [ -f "config/config.inc.php" ]; then
            # PrestaShop
            echo "✅ N'oubliez pas de mettre à jour config/config.inc.php avec:"
            echo "   DB: 'db', User: 'db', Pass: 'db', Host: 'db'"
        elif [ -f ".env" ]; then
            # Symfony/Laravel
            if grep -q "DATABASE_URL" .env; then
                echo "Mise à jour de .env..."
                cat > .env.local <<EOF
DATABASE_URL="mysql://db:db@db:3306/db?serverVersion=8.0"
EOF
                echo "✅ Créé .env.local avec la configuration DDEV"
            fi
        fi
        ;;
esac

# Définir les permissions
echo ""
echo "🔐 Configuration des permissions..."
ddev exec "find . -type d -exec chmod 755 {} \;" 2>/dev/null || true
ddev exec "find . -type f -exec chmod 644 {} \;" 2>/dev/null || true

# Installer les dépendances si composer.json existe
if [ -f "composer.json" ]; then
    echo ""
    echo "📦 Installation des dépendances Composer..."
    ddev composer install || echo "⚠️  Erreur lors de l'installation (non critique)"
fi

echo ""
echo "======================================"
echo "✅ Transformation LAMP → DDEV terminée!"
echo "======================================"
echo ""
echo "🌐 URL du site: https://$PROJECT_NAME.ddev.site"
echo ""
echo "📋 Nouvelle configuration de base de données:"
echo "   - Host: db"
echo "   - Database: db"
echo "   - User: db"
echo "   - Password: db"
echo "   - Port: 3306"
echo ""
echo "⚠️  ACTIONS REQUISES:"
echo "   1. Mettez à jour votre fichier de configuration avec les"
echo "      nouvelles informations de base de données ci-dessus"
echo "   2. Testez votre site: ddev launch"
echo "   3. Vérifiez les logs: ddev logs"
echo ""
echo "💾 Sauvegarde créée dans: ../$BACKUP_DIR"
echo ""
echo "📝 Commandes DDEV utiles:"
echo "   ddev start       - Démarrer le projet"
echo "   ddev stop        - Arrêter le projet"
echo "   ddev restart     - Redémarrer le projet"
echo "   ddev ssh         - Se connecter au conteneur"
echo "   ddev logs        - Voir les logs"
echo "   ddev describe    - Voir les informations du projet"
echo "   ddev mysql       - Accéder à MySQL"
echo ""
