# 🚀 Make VHost

Une solution d'automatisation intelligente pour la création de Virtual Hosts Apache et Nginx sur Linux.

## 📝 À propos

**Make VHost** est un script bash puissant et intuitif conçu pour simplifier la vie des développeurs web. Il automatise la configuration fastidieuse des serveurs web en détectant automatiquement la structure de votre projet et en appliquant les meilleures pratiques de configuration.

## ✨ Fonctionnalités

- 🔍 **Détection Automatique** : Identifie les types de projets (Symfony, PrestaShop, WordPress, Générique).
- 🌐 **Multi-Serveur** : Support complet pour **Apache2** (et httpd) ainsi que **Nginx**.
- 🐘 **Support PHP-FPM** : Configuration automatique du socket PHP-FPM le plus récent.
- 📂 **Gestion des Permissions** : Ajuste intelligemment les droits d'accès aux fichiers et dossiers.
- 📝 **Auto-Hosts** : Ajoute automatiquement l'entrée correspondante dans votre fichier `/etc/hosts`.
- ⚡ **Prêt à l'emploi** : Redémarrage automatique des services et tests de configuration inclus.

## 🛠️ Prérequis

- Un système d'exploitation Linux (basé sur Debian/Ubuntu ou RHEL).
- Un serveur web installé (**Apache** ou **Nginx**).
- Droits d'administrateur (**Sudo**).
- PHP installé (pour la détection de version).

## 🚀 Utilisation

1. **Rendre le script exécutable :**
   ```bash
   chmod +x make-vhost.sh
   ```

2. **Lancer le script :**
   ```bash
   sudo ./make-vhost.sh /chemin/vers/votre/projet [nom-de-domaine.local]
   ```

### Exemples :
```bash
# Utilisation par défaut (domaine généré : mon-projet.local)
sudo ./make-vhost.sh /var/www/mon-projet

# Spécifier un nom de domaine personnalisé
sudo ./make-vhost.sh /var/www/mon-projet mon-site.dev
```

## 🏗️ Frameworks Supportés

| Framework | Particularités |
| :--- | :--- |
| **Symfony** | Gestion du `public/`, configuration `FallbackResource` ou `try_files`. |
| **WordPress** | Configuration du DocumentRoot et règles de réécriture. |
| **PrestaShop** | Configuration optimisée et permissions spécifiques sur les dossiers sensibles. |
| **Générique** | Détection automatique du dossier `public/` si présent. |

## 🤝 Contributeurs

Ce projet a été développé avec passion par :

- **Eddy** (Développeur Principal)
- **Claude** (Assistant IA)

---

> Proposé par [TJ Eddy](https://github.com/tj-eddy)
