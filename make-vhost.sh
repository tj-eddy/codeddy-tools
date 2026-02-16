#!/bin/bash

###############################################################################
# Script: make-vhost.sh
# Description: Crée automatiquement un virtual host pour Apache
#              Supporte: Symfony, PrestaShop, WordPress
# Usage: sudo ./make-vhost.sh /chemin/vers/projet
###############################################################################

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Vérifier les droits root
if [[ $EUID -ne 0 ]]; then
   print_error "Ce script doit être exécuté en tant que root (utilisez sudo)"
   exit 1
fi

# Vérifier les arguments
if [ -z "$1" ]; then
    print_error "Usage: sudo $0 /chemin/vers/projet [nom-domaine.local]"
    echo ""
    echo "Exemples:"
    echo "  sudo $0 /var/www/mon-projet"
    echo "  sudo $0 /var/www/mon-projet monsite.local"
    exit 1
fi

PROJECT_PATH="$1"

# Vérifier que le chemin existe
if [ ! -d "$PROJECT_PATH" ]; then
    print_error "Le dossier '$PROJECT_PATH' n'existe pas"
    exit 1
fi

# Obtenir le chemin absolu
PROJECT_PATH=$(realpath "$PROJECT_PATH")
PROJECT_NAME=$(basename "$PROJECT_PATH")

# Nom de domaine (utiliser l'argument ou générer automatiquement)
if [ -z "$2" ]; then
    DOMAIN="${PROJECT_NAME}.local"
else
    DOMAIN="$2"
fi

print_info "=== Configuration du Virtual Host ==="
echo "Projet: $PROJECT_NAME"
echo "Chemin: $PROJECT_PATH"
echo "Domaine: $DOMAIN"
echo ""

# Détecter le type de projet
PROJECT_TYPE="generic"
DOCUMENT_ROOT="$PROJECT_PATH"

if [ -f "$PROJECT_PATH/symfony.lock" ] || [ -f "$PROJECT_PATH/bin/console" ]; then
    PROJECT_TYPE="symfony"
    DOCUMENT_ROOT="$PROJECT_PATH/public"
    print_info "Type de projet détecté: Symfony"
elif [ -f "$PROJECT_PATH/config/settings.inc.php" ] || [ -d "$PROJECT_PATH/modules" ]; then
    PROJECT_TYPE="prestashop"
    DOCUMENT_ROOT="$PROJECT_PATH"
    print_info "Type de projet détecté: PrestaShop"
elif [ -f "$PROJECT_PATH/wp-config.php" ] || [ -d "$PROJECT_PATH/wp-content" ]; then
    PROJECT_TYPE="wordpress"
    DOCUMENT_ROOT="$PROJECT_PATH"
    print_info "Type de projet détecté: WordPress"
else
    print_warning "Type de projet non détecté, utilisation de la configuration générique"
    # Vérifier si un dossier public existe
    if [ -d "$PROJECT_PATH/public" ]; then
        DOCUMENT_ROOT="$PROJECT_PATH/public"
    fi
fi

# Déterminer le serveur web utilisé
WEB_SERVER=""
if systemctl is-active --quiet apache2 2>/dev/null; then
    WEB_SERVER="apache"
    print_info "Serveur web: Apache"
elif systemctl is-active --quiet httpd 2>/dev/null; then
    WEB_SERVER="apache"
    print_info "Serveur web: Apache (httpd)"
elif systemctl is-active --quiet nginx 2>/dev/null; then
    WEB_SERVER="nginx"
    print_info "Serveur web: Nginx"
else
    print_error "Aucun serveur web détecté (Apache ou Nginx)"
    print_info "Installation d'Apache recommandée: sudo apt install apache2"
    exit 1
fi

# Configuration Apache
if [ "$WEB_SERVER" = "apache" ]; then

    # Déterminer les chemins Apache
    if [ -d "/etc/apache2/sites-available" ]; then
        APACHE_SITES_AVAILABLE="/etc/apache2/sites-available"
        APACHE_SITES_ENABLED="/etc/apache2/sites-enabled"
        APACHE_SERVICE="apache2"
    elif [ -d "/etc/httpd/sites-available" ]; then
        APACHE_SITES_AVAILABLE="/etc/httpd/sites-available"
        APACHE_SITES_ENABLED="/etc/httpd/sites-enabled"
        APACHE_SERVICE="httpd"
        # Créer le dossier sites-enabled s'il n'existe pas
        mkdir -p "$APACHE_SITES_ENABLED"
    else
        print_error "Dossier de configuration Apache non trouvé"
        exit 1
    fi

    VHOST_FILE="$APACHE_SITES_AVAILABLE/${DOMAIN}.conf"

    print_info "Création du fichier de configuration Apache..."

    # Configuration spécifique selon le type de projet
    cat > "$VHOST_FILE" << EOF
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ServerAlias www.${DOMAIN}

    DocumentRoot ${DOCUMENT_ROOT}

    <Directory ${DOCUMENT_ROOT}>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted

EOF

    # Ajout de configurations spécifiques
    if [ "$PROJECT_TYPE" = "symfony" ]; then
        cat >> "$VHOST_FILE" << EOF
        # Configuration Symfony
        FallbackResource /index.php
EOF
    elif [ "$PROJECT_TYPE" = "prestashop" ]; then
        cat >> "$VHOST_FILE" << EOF
        # Configuration PrestaShop
        <IfModule mod_rewrite.c>
            RewriteEngine On
        </IfModule>
EOF
    elif [ "$PROJECT_TYPE" = "wordpress" ]; then
        cat >> "$VHOST_FILE" << EOF
        # Configuration WordPress
        <IfModule mod_rewrite.c>
            RewriteEngine On
            RewriteBase /
        </IfModule>
EOF
    fi

    cat >> "$VHOST_FILE" << EOF
    </Directory>

    # Logs
    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}-error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}-access.log combined

EOF

    # Détecter la version PHP installée
    PHP_VERSION=$(php -v 2>/dev/null | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    PHP_SOCK="/var/run/php/php${PHP_VERSION}-fpm.sock"

    # Vérifier si le socket PHP-FPM existe
    if [ -S "$PHP_SOCK" ]; then
        cat >> "$VHOST_FILE" << EOF
    # PHP Configuration
    <FilesMatch \.php$>
        SetHandler "proxy:unix:${PHP_SOCK}|fcgi://localhost"
    </FilesMatch>

EOF
    elif [ -S "/var/run/php/php-fpm.sock" ]; then
        cat >> "$VHOST_FILE" << EOF
    # PHP Configuration
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/var/run/php/php-fpm.sock|fcgi://localhost"
    </FilesMatch>

EOF
    else
        print_warning "Socket PHP-FPM non trouvé, configuration PHP non ajoutée"
    fi

    cat >> "$VHOST_FILE" << EOF
</VirtualHost>
EOF

    print_success "Fichier de configuration créé: $VHOST_FILE"

    # Activer les modules Apache nécessaires
    print_info "Activation des modules Apache nécessaires..."
    a2enmod rewrite proxy_fcgi setenvif 2>/dev/null || true

    # Activer le site
    print_info "Activation du virtual host..."
    if command -v a2ensite &> /dev/null; then
        a2ensite "${DOMAIN}.conf"
    else
        # Pour les systèmes sans a2ensite (CentOS, etc.)
        ln -sf "$VHOST_FILE" "$APACHE_SITES_ENABLED/${DOMAIN}.conf"
    fi

    print_success "Virtual host activé"

# Configuration Nginx
elif [ "$WEB_SERVER" = "nginx" ]; then

    VHOST_FILE="/etc/nginx/sites-available/${DOMAIN}"

    print_info "Création du fichier de configuration Nginx..."

    cat > "$VHOST_FILE" << EOF
server {
    listen 80;
    listen [::]:80;

    server_name ${DOMAIN} www.${DOMAIN};
    root ${DOCUMENT_ROOT};

    index index.php index.html index.htm;

    access_log /var/log/nginx/${DOMAIN}-access.log;
    error_log /var/log/nginx/${DOMAIN}-error.log;

    location / {
EOF

    if [ "$PROJECT_TYPE" = "symfony" ]; then
        cat >> "$VHOST_FILE" << EOF
        # Configuration Symfony
        try_files \$uri /index.php\$is_args\$args;
EOF
    elif [ "$PROJECT_TYPE" = "wordpress" ]; then
        cat >> "$VHOST_FILE" << EOF
        # Configuration WordPress
        try_files \$uri \$uri/ /index.php?\$args;
EOF
    else
        cat >> "$VHOST_FILE" << EOF
        try_files \$uri \$uri/ /index.php?\$query_string;
EOF
    fi

    cat >> "$VHOST_FILE" << EOF
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    print_success "Fichier de configuration créé: $VHOST_FILE"

    # Activer le site
    print_info "Activation du virtual host..."
    mkdir -p /etc/nginx/sites-enabled
    ln -sf "$VHOST_FILE" "/etc/nginx/sites-enabled/${DOMAIN}"

    print_success "Virtual host activé"
fi

# Ajouter l'entrée dans /etc/hosts
print_info "Configuration du fichier /etc/hosts..."

if grep -q "127.0.0.1.*${DOMAIN}" /etc/hosts; then
    print_warning "L'entrée pour ${DOMAIN} existe déjà dans /etc/hosts"
else
    echo "127.0.0.1    ${DOMAIN} www.${DOMAIN}" >> /etc/hosts
    print_success "Entrée ajoutée dans /etc/hosts"
fi

# Ajuster les permissions
print_info "Ajustement des permissions..."

# Obtenir l'utilisateur qui a exécuté sudo
REAL_USER="${SUDO_USER:-$USER}"

# Permissions du projet
chown -R "$REAL_USER:www-data" "$PROJECT_PATH"
find "$PROJECT_PATH" -type d -exec chmod 755 {} \;
find "$PROJECT_PATH" -type f -exec chmod 644 {} \;

# Permissions spécifiques selon le type
if [ "$PROJECT_TYPE" = "symfony" ]; then
    # Symfony: var doit être writable
    if [ -d "$PROJECT_PATH/var" ]; then
        chmod -R 775 "$PROJECT_PATH/var"
    fi
    if [ -f "$PROJECT_PATH/bin/console" ]; then
        chmod +x "$PROJECT_PATH/bin/console"
    fi
elif [ "$PROJECT_TYPE" = "prestashop" ]; then
    # PrestaShop: plusieurs dossiers doivent être writables
    for dir in cache config download img log mails modules themes translations upload var; do
        if [ -d "$PROJECT_PATH/$dir" ]; then
            chmod -R 775 "$PROJECT_PATH/$dir"
        fi
    done
elif [ "$PROJECT_TYPE" = "wordpress" ]; then
    # WordPress: wp-content doit être writable
    if [ -d "$PROJECT_PATH/wp-content" ]; then
        chmod -R 775 "$PROJECT_PATH/wp-content"
    fi
fi

print_success "Permissions ajustées"

# Tester la configuration
print_info "Test de la configuration..."

if [ "$WEB_SERVER" = "apache" ]; then
    if apachectl configtest 2>/dev/null; then
        print_success "Configuration Apache valide"
    else
        print_warning "Test de configuration Apache (certains avertissements peuvent être ignorés)"
        apachectl configtest 2>&1 | grep -i "syntax" || true
    fi
elif [ "$WEB_SERVER" = "nginx" ]; then
    if nginx -t 2>/dev/null; then
        print_success "Configuration Nginx valide"
    else
        print_error "Erreur dans la configuration Nginx"
        nginx -t
        exit 1
    fi
fi

# Redémarrer le serveur web
print_info "Redémarrage du serveur web..."

if [ "$WEB_SERVER" = "apache" ]; then
    systemctl reload $APACHE_SERVICE
    print_success "Apache redémarré"
else
    systemctl reload nginx
    print_success "Nginx redémarré"
fi

# Résumé final
echo ""
print_success "=== Virtual Host créé avec succès! ==="
echo ""
echo "📋 Informations:"
echo "   Domaine: http://${DOMAIN}"
echo "   Type: $PROJECT_TYPE"
echo "   Chemin: $PROJECT_PATH"
echo "   Document Root: $DOCUMENT_ROOT"
echo "   Configuration: $VHOST_FILE"
echo ""
print_info "Ouvrez votre navigateur et accédez à: http://${DOMAIN}"
echo ""

# Suggestions selon le type de projet
if [ "$PROJECT_TYPE" = "symfony" ]; then
    echo "💡 Conseils Symfony:"
    echo "   - Installez les dépendances: composer install"
    echo "   - Configurez .env avec vos paramètres"
    echo "   - Videz le cache: php bin/console cache:clear"
elif [ "$PROJECT_TYPE" = "prestashop" ]; then
    echo "💡 Conseils PrestaShop:"
    echo "   - Accédez à http://${DOMAIN}/install pour l'installation"
    echo "   - Supprimez le dossier /install après installation"
    echo "   - Configurez config/settings.inc.php"
elif [ "$PROJECT_TYPE" = "wordpress" ]; then
    echo "💡 Conseils WordPress:"
    echo "   - Accédez à http://${DOMAIN}/wp-admin/install.php"
    echo "   - Configurez wp-config.php avec vos paramètres DB"
fi

echo ""
print_success "Configuration terminée!"
