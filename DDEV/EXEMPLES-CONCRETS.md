# 🎯 GUIDE PRATIQUE - Exemples Concrets d'Utilisation

Ce guide vous montre des exemples réels d'utilisation des scripts avec des captures de ce que vous verrez.

---

## 📍 SCÉNARIO 1 : Installation Complète depuis Zéro

### Contexte
Vous avez un Linux Mint fraîchement installé et vous voulez développer avec WordPress.

### Étapes détaillées

#### 1️⃣ Télécharger les scripts

```bash
# Créer un dossier pour les scripts
mkdir ~/ddev-scripts
cd ~/ddev-scripts

# Télécharger les scripts (ou les copier)
# Rendre exécutables
chmod +x *.sh
```

#### 2️⃣ Installer Docker et DDEV

```bash
bash install-ddev-docker.sh
```

**Ce que vous verrez :**
```
======================================
Installation de Docker et DDEV
======================================

📦 Mise à jour du système...
Hit:1 http://packages.linuxmint.com virginia InRelease
...

📦 Installation des dépendances...
Reading package lists... Done
...

🐳 Installation de Docker Engine...
...

✅ Vérification de Docker...
Docker version 24.0.7, build afdd53b

====================================
✅ Installation terminée avec succès!
====================================

⚠️  IMPORTANT: Vous devez vous déconnecter et vous reconnecter
```

**ACTION REQUISE :**
```bash
# Option 1 : Déconnexion
logout

# Option 2 : Redémarrage
sudo reboot
```

#### 3️⃣ Vérifier l'installation (après reconnexion)

```bash
docker --version
# Docker version 24.0.7, build afdd53b

ddev version
# ddev version v1.22.7

docker run hello-world
# Hello from Docker!
```

#### 4️⃣ Créer votre premier site WordPress

```bash
cd ~/projets
bash ~/ddev-scripts/install-wordpress-ddev.sh
```

**Interaction avec le script :**
```
======================================
Installation de WordPress avec DDEV
======================================

Nom du projet WordPress (par défaut: wordpress): mon-blog
Titre du site (par défaut: Mon Site WordPress): Mon Blog Personnel
Nom d'utilisateur admin (par défaut: admin): john
Email admin (par défaut: admin@example.com): john@example.com
Mot de passe admin (par défaut: admin123): MonMotDePasse2024!

📁 Création du dossier du projet: mon-blog
⚙️  Configuration de DDEV...
Successfully created ddev configuration in /home/user/projets/mon-blog

🚀 Démarrage de DDEV...
Starting mon-blog...
Successfully started mon-blog
...

====================================
✅ WordPress installé avec succès!
====================================

🌐 URL du site: https://mon-blog.ddev.site
🔐 URL admin: https://mon-blog.ddev.site/wp-admin

📋 Informations de connexion:
   - Utilisateur: john
   - Mot de passe: MonMotDePasse2024!
   - Email: john@example.com

🚀 Pour ouvrir le site:
   ddev launch
```

#### 5️⃣ Accéder au site

```bash
cd ~/projets/mon-blog
ddev launch
```

Votre navigateur s'ouvre automatiquement sur `https://mon-blog.ddev.site` 🎉

---

## 📍 SCÉNARIO 2 : Migrer un Site WordPress LAMP Existant

### Contexte
Vous avez un site WordPress dans `/var/www/ancien-blog` avec Apache et MySQL, et vous voulez le migrer vers DDEV.

### Situation actuelle
```
/var/www/ancien-blog/
├── wp-admin/
├── wp-content/
├── wp-includes/
├── wp-config.php
└── ...

Base de données MySQL:
- Host: localhost
- Database: ancien_blog_db
- User: root
- Password: mysql_root_pass
```

### Étapes de migration

#### 1️⃣ Aller dans le dossier du projet

```bash
cd /var/www/ancien-blog
```

#### 2️⃣ Lancer la transformation

```bash
bash ~/ddev-scripts/transform-lamp-to-ddev.sh
```

#### 3️⃣ Répondre aux questions

**Ce que vous verrez et comment répondre :**
```
======================================
Transformation LAMP vers DDEV
======================================

📋 Ce script va transformer votre projet LAMP en projet DDEV
   Assurez-vous d'être dans le dossier racine de votre projet

Êtes-vous dans le bon dossier? (/var/www/ancien-blog) [O/n]: O

🔍 Détection du type de projet...
✅ Projet WordPress détecté

Nom du projet DDEV (par défaut: ancien-blog): mon-ancien-blog
Version PHP (par défaut: 8.1): 8.1

🗄️  Configuration de la base de données

Nom de l'hôte MySQL actuel (par défaut: localhost): localhost
Nom de la base de données: ancien_blog_db
Utilisateur MySQL: root
Mot de passe MySQL: [tapez votre mot de passe]
Voulez-vous importer la base de données existante? [O/n]: O

💾 Création d'une sauvegarde...
✅ Sauvegarde créée dans ../backup-lamp-20260217_143022

📤 Export de la base de données...
-- MySQL dump 10.13  Distrib 8.0.35
...

⚙️  Configuration de DDEV...
🚀 Démarrage de DDEV...
📥 Import de la base de données dans DDEV...
Successfully imported database 'db'

📝 Mise à jour de la configuration...
✅ Créé wp-config-ddev.php (à fusionner avec wp-config.php)

====================================
✅ Transformation LAMP → DDEV terminée!
====================================

🌐 URL du site: https://mon-ancien-blog.ddev.site

📋 Nouvelle configuration de base de données:
   - Host: db
   - Database: db
   - User: db
   - Password: db

⚠️  ACTIONS REQUISES:
   1. Mettez à jour votre fichier de configuration avec les
      nouvelles informations de base de données ci-dessus
```

#### 4️⃣ Mettre à jour wp-config.php

```bash
nano wp-config.php
```

**Modifier ces lignes :**
```php
// AVANT (LAMP)
define('DB_NAME', 'ancien_blog_db');
define('DB_USER', 'root');
define('DB_PASSWORD', 'mysql_root_pass');
define('DB_HOST', 'localhost');

// APRÈS (DDEV)
define('DB_NAME', 'db');
define('DB_USER', 'db');
define('DB_PASSWORD', 'db');
define('DB_HOST', 'db');
```

#### 5️⃣ Tester le site

```bash
ddev launch
```

#### 6️⃣ Arrêter Apache (optionnel)

```bash
# Arrêter Apache pour libérer le port 80
sudo systemctl stop apache2
sudo systemctl disable apache2
```

---

## 📍 SCÉNARIO 3 : Créer une Boutique PrestaShop

### Contexte
Vous voulez créer une boutique e-commerce avec PrestaShop.

### Étapes

#### 1️⃣ Créer le projet

```bash
cd ~/projets
bash ~/ddev-scripts/install-prestashop-ddev.sh
```

#### 2️⃣ Interaction

```
======================================
Installation de PrestaShop avec DDEV
======================================

Nom du projet PrestaShop (par défaut: prestashop): ma-boutique

Versions disponibles:
  1) PrestaShop 8.x (latest)
  2) PrestaShop 1.7.x
Choisir la version (1 ou 2, défaut: 1): 1

📁 Création du dossier du projet: ma-boutique
⚙️  Configuration de DDEV...
🚀 Démarrage de DDEV...
📥 Téléchargement de PrestaShop 8.1.7...
📦 Extraction de PrestaShop...

====================================
✅ PrestaShop est prêt pour l'installation!
====================================

🌐 URL du site: https://ma-boutique.ddev.site

📋 Informations pour l'installation web:
   - URL de la base de données: db
   - Nom de la base: db
   - Utilisateur: db
   - Mot de passe: db
```

#### 3️⃣ Terminer l'installation via le navigateur

```bash
cd ~/projets/ma-boutique
ddev launch
```

**Dans le navigateur, vous verrez l'assistant PrestaShop :**

1. **Langue** : Choisir Français
2. **Licence** : Accepter
3. **Informations boutique** :
   - Nom : Ma Boutique
   - Email : contact@ma-boutique.com
   - Mot de passe : [votre mot de passe admin]

4. **Configuration système** :
   - Serveur base de données : `db`
   - Nom de la base : `db`
   - Login : `db`
   - Mot de passe : `db`

5. **Installation** : Attendre la fin

#### 4️⃣ Supprimer le dossier install

```bash
cd ~/projets/ma-boutique
ddev exec "rm -rf public/install"
ddev launch
```

---

## 📍 SCÉNARIO 4 : Développer une API Symfony

### Contexte
Vous développez une API REST avec Symfony.

### Étapes

#### 1️⃣ Créer le projet

```bash
cd ~/projets
bash ~/ddev-scripts/install-symfony-ddev.sh
```

#### 2️⃣ Interaction

```
======================================
Installation de Symfony avec DDEV
======================================

Nom du projet Symfony (par défaut: symfony): mon-api

Types de projets disponibles:
  1) Application web complète (symfony/skeleton + webapp)
  2) Application web (symfony/website-skeleton)
  3) API (symfony/skeleton)
  4) Microservice (symfony/skeleton minimal)
Choisir le type (1-4, défaut: 1): 3

Version de Symfony (par défaut: latest, ou 6.4, 7.0): 7.0

📁 Création du dossier du projet: mon-api
⚙️  Configuration de DDEV...
🚀 Démarrage de DDEV...
📥 Création du projet Symfony...
Installation d'une API...

====================================
✅ Symfony installé avec succès!
====================================

🌐 URL du site: https://mon-api.ddev.site
```

#### 3️⃣ Créer votre premier endpoint

```bash
cd ~/projets/mon-api
ddev exec "php bin/console make:controller ApiController"
```

#### 4️⃣ Éditer le controller

```bash
nano src/Controller/ApiController.php
```

```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

class ApiController extends AbstractController
{
    #[Route('/api/hello', name: 'api_hello', methods: ['GET'])]
    public function hello(): JsonResponse
    {
        return $this->json([
            'message' => 'Hello from my API!',
            'timestamp' => time(),
        ]);
    }
}
```

#### 5️⃣ Tester l'API

```bash
ddev launch /api/hello
```

Résultat :
```json
{
  "message": "Hello from my API!",
  "timestamp": 1708196400
}
```

---

## 📍 SCÉNARIO 5 : Gérer Plusieurs Projets en Parallèle

### Contexte
Vous travaillez sur 3 projets en même temps : WordPress, PrestaShop et Symfony.

### Structure des projets

```
~/projets/
├── blog-wordpress/
├── boutique-prestashop/
└── api-symfony/
```

### Commandes quotidiennes

#### Démarrer tous les projets

```bash
# Projet 1 : Blog WordPress
cd ~/projets/blog-wordpress
ddev start

# Projet 2 : Boutique PrestaShop
cd ~/projets/boutique-prestashop
ddev start

# Projet 3 : API Symfony
cd ~/projets/api-symfony
ddev start
```

#### Voir l'état de tous les projets

```bash
ddev list
```

**Résultat :**
```
NAME                 STATUS   LOCATION                        URL(S)
blog-wordpress       running  ~/projets/blog-wordpress        https://blog-wordpress.ddev.site
boutique-prestashop  running  ~/projets/boutique-prestashop   https://boutique-prestashop.ddev.site
api-symfony          running  ~/projets/api-symfony           https://api-symfony.ddev.site
```

#### Arrêter un projet spécifique

```bash
cd ~/projets/blog-wordpress
ddev stop
```

#### Arrêter tous les projets

```bash
ddev poweroff
```

#### Redémarrer rapidement

```bash
# Démarrer le dernier projet utilisé
cd ~/projets/blog-wordpress
ddev start

# Ouvrir dans le navigateur
ddev launch
```

---

## 📍 SCÉNARIO 6 : Travailler avec une Équipe

### Contexte
Votre collègue vous envoie un projet DDEV, vous devez le démarrer.

### Étapes

#### 1️⃣ Cloner le projet

```bash
cd ~/projets
git clone https://github.com/equipe/projet-client.git
cd projet-client
```

#### 2️⃣ Vérifier la configuration DDEV

```bash
ls -la .ddev/
# Vous devriez voir config.yaml
```

#### 3️⃣ Démarrer le projet

```bash
ddev start
```

**Ce qui se passe automatiquement :**
- DDEV lit la configuration dans `.ddev/config.yaml`
- Télécharge les images Docker nécessaires
- Crée les conteneurs
- Configure la base de données
- Installe les dépendances Composer

#### 4️⃣ Importer la base de données (si fournie)

```bash
# Si votre collègue a fourni un dump
ddev import-db --file=database_dump.sql.gz

# Ou depuis un fichier non compressé
ddev import-db --file=database.sql
```

#### 5️⃣ Installer les dépendances

```bash
# Pour PHP/Composer
ddev composer install

# Pour Node.js (si applicable)
ddev exec "npm install"
```

#### 6️⃣ Accéder au site

```bash
ddev launch
```

---

## 📍 SCÉNARIO 7 : Débogage d'un Problème

### Contexte
Votre site WordPress affiche une erreur 500.

### Diagnostic étape par étape

#### 1️⃣ Voir les logs

```bash
cd ~/projets/mon-blog
ddev logs
```

**Regardez les dernières lignes :**
```
[error] PHP Fatal error: Uncaught Error: Call to undefined function...
```

#### 2️⃣ Vérifier la configuration

```bash
ddev describe
```

**Sortie :**
```
NAME          TYPE       LOCATION                URL
mon-blog      wordpress  ~/projets/mon-blog      https://mon-blog.ddev.site
PHP version:  8.1
```

#### 3️⃣ Se connecter au conteneur

```bash
ddev ssh
```

**Vous êtes maintenant dans le conteneur :**
```bash
# Vérifier les permissions
ls -la wp-content/
drwxrwxrwx 5 www-data www-data 4096 Feb 17 14:30 uploads

# Vérifier les erreurs PHP
tail -f /var/log/php-fpm-error.log

# Sortir du conteneur
exit
```

#### 4️⃣ Redémarrer proprement

```bash
# Redémarrage simple
ddev restart

# Redémarrage avec reconstruction
ddev restart --rebuild

# Arrêter et redémarrer
ddev stop
ddev start
```

#### 5️⃣ Vérifier la base de données

```bash
# Accéder à MySQL
ddev mysql

# Dans MySQL
mysql> SHOW DATABASES;
mysql> USE db;
mysql> SHOW TABLES;
mysql> SELECT * FROM wp_options WHERE option_name = 'siteurl';
mysql> exit
```

---

## 🛠️ Commandes Pratiques au Quotidien

### WordPress

```bash
# Mettre à jour WordPress
cd mon-blog
ddev exec "wp core update --path=wordpress"

# Installer un plugin
ddev exec "wp plugin install contact-form-7 --activate --path=wordpress"

# Créer un utilisateur
ddev exec "wp user create bob bob@example.com --role=editor --path=wordpress"

# Exporter la base de données
ddev export-db > backup-$(date +%Y%m%d).sql
```

### PrestaShop

```bash
# Nettoyer le cache
cd ma-boutique
ddev exec "rm -rf public/var/cache/*"

# Régénérer les images
ddev exec "php public/bin/console prestashop:images:regenerate"
```

### Symfony

```bash
# Créer une entité
cd mon-api
ddev exec "php bin/console make:entity Product"

# Créer une migration
ddev exec "php bin/console make:migration"

# Exécuter les migrations
ddev exec "php bin/console doctrine:migrations:migrate"

# Vider le cache
ddev exec "php bin/console cache:clear"
```

### Tous projets

```bash
# Voir l'utilisation des ressources
docker stats

# Nettoyer Docker
docker system prune -a

# Sauvegarder tout
ddev snapshot

# Restaurer
ddev snapshot restore
```

---

## ✅ Checklist de Dépannage Rapide

```bash
# 1. Le site ne démarre pas
ddev restart --rebuild

# 2. Erreur de port occupé
sudo systemctl stop apache2
sudo systemctl stop nginx
ddev start

# 3. Erreur de permissions
cd mon-projet
ddev exec "chmod -R 777 var/"

# 4. Base de données perdue
ddev import-db --file=backup.sql

# 5. Tout réinitialiser
ddev delete -Oy
# Puis recréer avec le script d'installation
```

---

**Avec ces exemples, vous êtes prêt à utiliser DDEV efficacement ! 🚀**
