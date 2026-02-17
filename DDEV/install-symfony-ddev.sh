#!/bin/bash
#
# Script d'installation de Symfony dans DDEV
# Version corrigée — bugs résolus :
#   - hook cache:clear supprimé (s'exécutait avant l'install)
#   - syntaxe "ddev composer create-project" correcte
#   - version Symfony passée dans le nom du package (ex: symfony/skeleton:"^7.0")
#

set -e

echo "======================================"
echo "Installation de Symfony avec DDEV"
echo "======================================"
echo ""

# Demander le nom du projet
read -p "Nom du projet Symfony (par défaut: symfony): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-symfony}

# Demander le type de projet
echo ""
echo "Types de projets disponibles:"
echo "  1) Application web complète (symfony/skeleton + webapp)"
echo "  2) API REST (symfony/skeleton + api-platform)"
echo "  3) Skeleton minimal (symfony/skeleton)"
echo "  4) Site web classique (symfony/website-skeleton)"
read -p "Choisir le type (1-4, défaut: 1): " PROJECT_TYPE
PROJECT_TYPE=${PROJECT_TYPE:-1}

# Demander la version de Symfony
echo ""
echo "Version de Symfony :"
echo "  - Laisser vide pour la dernière stable"
echo "  - Exemples : 6.4, 7.0, 7.1"
read -p "Version (défaut: dernière stable): " SYMFONY_VERSION

# Créer le dossier du projet
echo ""
echo "📁 Création du dossier du projet: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Configurer DDEV (SANS hook post-start : Symfony n'est pas encore installé)
echo ""
echo "⚙️  Configuration de DDEV..."
ddev config \
    --project-type=symfony \
    --php-version=8.2 \
    --docroot=public \
    --project-name="$PROJECT_NAME"

# Démarrer DDEV
echo ""
echo "🚀 Démarrage de DDEV..."
ddev start

# Vérification de Composer
echo ""
echo "📦 Vérification de Composer..."
ddev composer --version

# Construire l'argument package avec version optionnelle
# Syntaxe correcte : symfony/skeleton:"^7.0"
build_package_arg() {
    local PACKAGE=$1
    if [ -n "$SYMFONY_VERSION" ]; then
        local CLEAN_VERSION=$(echo "$SYMFONY_VERSION" | sed 's/\^//')
        echo "${PACKAGE}:\"^${CLEAN_VERSION}\""
    else
        echo "$PACKAGE"
    fi
}

# Créer le projet Symfony dans un dossier temporaire puis déplacer
echo ""
echo "📥 Création du projet Symfony..."

case $PROJECT_TYPE in
    1)
        echo "Installation d'une application web complète..."
        PACKAGE=$(build_package_arg "symfony/skeleton")
        ddev exec "composer create-project $PACKAGE /tmp/sf_install --no-interaction"
        ddev exec "cp -rT /tmp/sf_install /var/www/html && rm -rf /tmp/sf_install"
        echo "➕ Ajout du pack webapp..."
        ddev composer require webapp --no-interaction
        ;;
    2)
        echo "Installation d'une API REST..."
        PACKAGE=$(build_package_arg "symfony/skeleton")
        ddev exec "composer create-project $PACKAGE /tmp/sf_install --no-interaction"
        ddev exec "cp -rT /tmp/sf_install /var/www/html && rm -rf /tmp/sf_install"
        echo "➕ Ajout d'API Platform..."
        ddev composer require api --no-interaction
        ;;
    3)
        echo "Installation d'un skeleton minimal..."
        PACKAGE=$(build_package_arg "symfony/skeleton")
        ddev exec "composer create-project $PACKAGE /tmp/sf_install --no-interaction"
        ddev exec "cp -rT /tmp/sf_install /var/www/html && rm -rf /tmp/sf_install"
        ;;
    4)
        echo "Installation d'un site web classique..."
        PACKAGE=$(build_package_arg "symfony/website-skeleton")
        ddev exec "composer create-project $PACKAGE /tmp/sf_install --no-interaction"
        ddev exec "cp -rT /tmp/sf_install /var/www/html && rm -rf /tmp/sf_install"
        ;;
esac

# Vérifier que l'installation a réussi
echo ""
echo "🔎 Vérification de l'installation..."
if [ ! -f "bin/console" ]; then
    echo "❌ Erreur : bin/console introuvable. L'installation a échoué."
    exit 1
fi
echo "✅ bin/console trouvé"

# Configurer la base de données
echo ""
echo "🗄️  Configuration de la base de données..."
cat > .env.local <<'EOF'
DATABASE_URL="mysql://db:db@db:3306/db?serverVersion=8.0&charset=utf8mb4"
APP_ENV=dev
APP_DEBUG=true
EOF
echo "✅ .env.local créé"

# Créer la base de données
ddev exec "php bin/console doctrine:database:create --if-not-exists" \
    || echo "⚠️  Doctrine pas encore installé (normal pour skeleton minimal)"

# Permissions sur var/
echo ""
echo "🔐 Configuration des permissions..."
ddev exec "mkdir -p var && chmod -R 777 var/"

# Outils de développement
echo ""
echo "📦 Installation des outils de développement..."
ddev composer require --dev \
    symfony/maker-bundle \
    symfony/profiler-pack \
    --no-interaction || echo "⚠️  Certains outils dev n'ont pas pu être installés"

# Cache clear — APRÈS l'installation complète
echo ""
echo "🧹 Nettoyage du cache..."
ddev exec "php bin/console cache:clear"
echo "✅ Cache vidé"

# Ajouter le hook post-start MAINTENANT que l'appli existe
echo ""
echo "⚙️  Ajout du hook post-start DDEV..."
cat >> .ddev/config.yaml <<'YAMLEOF'

hooks:
  post-start:
    - exec: "composer install --no-interaction 2>/dev/null || true"
    - exec: "php bin/console cache:warmup 2>/dev/null || true"
YAMLEOF

echo ""
echo "======================================"
echo "✅ Symfony installé avec succès!"
echo "======================================"
echo ""
ddev exec "php bin/console about" 2>/dev/null || true
echo ""
echo "🌐 URL du site: https://$PROJECT_NAME.ddev.site"
echo ""
echo "🚀 Ouvrir le site :"
echo "   ddev launch"
echo ""
echo "📋 Base de données :"
echo "   Host     : db"
echo "   Database : db"
echo "   User     : db"
echo "   Password : db"
echo "   Port     : 3306"
echo ""
echo "📝 Commandes Symfony utiles :"
echo "   ddev exec 'php bin/console list'"
echo "   ddev exec 'php bin/console make:controller NomController'"
echo "   ddev exec 'php bin/console make:entity NomEntite'"
echo "   ddev exec 'php bin/console make:migration'"
echo "   ddev exec 'php bin/console doctrine:migrations:migrate'"
echo "   ddev exec 'php bin/console debug:router'"
echo ""
echo "📝 Bundles souvent utiles :"
echo "   ddev composer require symfony/security-bundle"
echo "   ddev composer require symfony/mailer"
echo "   ddev composer require symfony/form symfony/validator"
echo "   ddev composer require twig/twig"
echo ""
echo "📝 Commandes DDEV utiles:"
echo "   ddev start       - Démarrer le projet"
echo "   ddev stop        - Arrêter le projet"
echo "   ddev restart     - Redémarrer le projet"
echo "   ddev ssh         - Se connecter au conteneur"
echo "   ddev logs        - Voir les logs"
echo "   ddev describe    - Voir les informations du projet"
echo ""
