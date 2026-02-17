# Scripts d'installation DDEV et CMS

Ce dossier contient des scripts shell pour installer DDEV avec Docker sur Linux Mint et créer des projets pour différents CMS.

## 📋 Liste des scripts

### 1. `install-ddev-docker.sh`
Installation complète de Docker et DDEV sur Linux Mint.

**Utilisation:**
```bash
bash install-ddev-docker.sh
```

**Ce script installe:**
- Docker Engine et Docker Compose
- DDEV
- mkcert (pour HTTPS)
- Configure les permissions utilisateur

**⚠️ Important:** Après l'exécution, vous devez vous déconnecter et vous reconnecter (ou redémarrer) pour que les changements prennent effet.

---

### 2. `install-prestashop-ddev.sh`
Crée un nouveau projet PrestaShop dans DDEV.

**Utilisation:**
```bash
bash install-prestashop-ddev.sh
```

**Le script vous demandera:**
- Nom du projet
- Version de PrestaShop (8.x ou 1.7.x)

**Après l'installation:**
- Accédez à l'URL fournie pour terminer l'installation via l'interface web
- Supprimez le dossier `install` après l'installation: `ddev exec 'rm -rf public/install'`

---

### 3. `install-wordpress-ddev.sh`
Crée un nouveau projet WordPress dans DDEV avec installation automatique.

**Utilisation:**
```bash
bash install-wordpress-ddev.sh
```

**Le script vous demandera:**
- Nom du projet
- Titre du site
- Nom d'utilisateur admin
- Email admin
- Mot de passe admin

**Installation automatique:**
- WordPress est entièrement configuré
- Base de données créée
- Thème français installé
- Permaliens configurés
- Prêt à utiliser immédiatement!

---

### 4. `install-symfony-ddev.sh`
Crée un nouveau projet Symfony dans DDEV.

**Utilisation:**
```bash
bash install-symfony-ddev.sh
```

**Le script vous demandera:**
- Nom du projet
- Type de projet (webapp, API, microservice)
- Version de Symfony

**Types de projets:**
1. Application web complète
2. Application web (website-skeleton)
3. API
4. Microservice

---

### 5. `transform-lamp-to-ddev.sh`
Transforme un projet LAMP existant en projet DDEV.

**Utilisation:**
```bash
cd /chemin/vers/votre/projet/lamp
bash /chemin/vers/transform-lamp-to-ddev.sh
```

**Le script va:**
- Détecter automatiquement le type de projet
- Créer une sauvegarde complète
- Exporter la base de données existante
- Configurer DDEV
- Importer la base de données
- Créer les fichiers de configuration nécessaires

**Projets supportés:**
- WordPress
- PrestaShop
- Symfony
- Laravel
- Drupal
- PHP générique

---

## 🚀 Guide d'utilisation rapide

### Installation initiale (première fois)

1. **Installer Docker et DDEV:**
```bash
bash install-ddev-docker.sh
```

2. **Se déconnecter et se reconnecter** (ou redémarrer)

3. **Vérifier l'installation:**
```bash
docker --version
docker compose version
ddev version
```

### Créer un nouveau projet

**Pour WordPress:**
```bash
bash install-wordpress-ddev.sh
```

**Pour PrestaShop:**
```bash
bash install-prestashop-ddev.sh
```

**Pour Symfony:**
```bash
bash install-symfony-ddev.sh
```

### Migrer un projet LAMP existant

```bash
cd /var/www/mon-ancien-projet
bash /chemin/vers/transform-lamp-to-ddev.sh
```

---

## 📝 Commandes DDEV utiles

Une fois votre projet créé, voici les commandes les plus utiles:

```bash
# Démarrer le projet
ddev start

# Arrêter le projet
ddev stop

# Redémarrer le projet
ddev restart

# Ouvrir le site dans le navigateur
ddev launch

# Se connecter au conteneur
ddev ssh

# Voir les logs
ddev logs

# Informations sur le projet
ddev describe

# Accéder à la base de données
ddev mysql

# Importer une base de données
ddev import-db --file=dump.sql

# Exporter la base de données
ddev export-db > dump.sql

# Lancer des commandes PHP
ddev exec php mon-script.php

# Lancer des commandes Composer
ddev composer install
ddev composer require vendor/package

# Pour WordPress
ddev exec 'wp plugin list --path=wordpress'

# Pour Symfony
ddev exec 'php bin/console list'
```

---

## 🔧 Configuration

### Ports et URLs

Par défaut, DDEV crée des URLs comme:
- `https://nom-projet.ddev.site`
- HTTP: Port 80 (automatique)
- HTTPS: Port 443 (automatique)
- MySQL: Port 3306 (interne)

### Base de données

Pour tous les projets DDEV, les identifiants sont:
- **Host:** `db`
- **Database:** `db`
- **User:** `db`
- **Password:** `db`
- **Port:** `3306`

### Fichiers et dossiers

- Configuration DDEV: `.ddev/`
- Fichier principal: `.ddev/config.yaml`
- Hooks personnalisés: `.ddev/config.*.yaml`

---

## 🆘 Dépannage

### Problème: Docker nécessite sudo

**Solution:** Vous devez vous déconnecter et vous reconnecter après l'installation.

```bash
# Ou ajoutez manuellement:
sudo usermod -aG docker $USER
# Puis déconnectez-vous et reconnectez-vous
```

### Problème: Port déjà utilisé

**Solution:** Arrêtez Apache/Nginx local:
```bash
sudo systemctl stop apache2
sudo systemctl stop nginx
```

Ou configurez DDEV pour utiliser d'autres ports:
```bash
ddev config --router-http-port=8080 --router-https-port=8443
```

### Problème: Erreur de mémoire ou performance

**Solution:** Augmentez les ressources Docker:
```bash
# Voir l'utilisation
docker stats

# Nettoyer Docker
docker system prune -a
```

### Problème: Site inaccessible

**Solution:**
```bash
# Redémarrer le projet
ddev restart

# Reconstruire
ddev restart --rebuild

# Vérifier les logs
ddev logs
```

---

## 📚 Ressources supplémentaires

- [Documentation DDEV](https://ddev.readthedocs.io/)
- [Documentation Docker](https://docs.docker.com/)
- [DDEV GitHub](https://github.com/ddev/ddev)

---

## ⚠️ Notes importantes

1. **Sauvegardez toujours** vos projets avant la migration
2. Les scripts créent automatiquement des sauvegardes lors de la transformation LAMP
3. Vérifiez que les ports 80 et 443 sont disponibles
4. Minimum 4 GB RAM recommandé pour Docker
5. DDEV fonctionne mieux avec une connexion internet pour télécharger les images Docker

---

## 🤝 Support

Pour obtenir de l'aide:
1. Consultez la documentation DDEV
2. Vérifiez les logs: `ddev logs`
3. Visitez la communauté DDEV sur Discord ou GitHub

---

**Bonne utilisation! 🎉**
