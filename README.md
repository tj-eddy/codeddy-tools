# CODEDDY - Tools 🛠️

Collection de scripts d'automatisation pour le développement web sous Linux (Debian, Ubuntu, Mint).

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/tj-eddy/codeddy-tools)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 📋 Présentation

Ce dépôt regroupe des outils essentiels pour optimiser votre flux de travail de développeur web sur Linux. Ils permettent d'automatiser des tâches répétitives comme la configuration de serveurs locaux ou le nettoyage du système.

## 📁 Structure du projet

```text
codeddy-tools/
├── make-vhost.sh       # Script de création de Virtual Hosts (Apache/Nginx)
├── lm-clean.sh         # Script de maintenance et nettoyage système
└── README.md           # Documentation principale
```

---

## 🚀 Scripts disponibles

### 1. `make-vhost.sh` - Configuration de serveurs

Automatise la création de Virtual Hosts pour **Apache** et **Nginx**. Idéal pour configurer rapidement vos projets locaux.

**Fonctionnalités :**
- 🔍 **Détection auto** : Identifie les projets Symfony, PrestaShop, WordPress ou génériques.
- ⚙️ **PHP-FPM** : Configuration automatique du socket PHP.
- 🔐 **Permissions** : Gestion intelligente des droits (www-data) selon le framework.
- 🌐 **Hosts** : Ajout automatique du nom de domaine dans `/etc/hosts`.
- ✅ **Validation** : Test de configuration avant le redémarrage du service.

**Utilisation :**
```bash
# Syntaxe : sudo ./make-vhost.sh [CHEMIN_PROJET] [NOM_DOMAINE]
sudo ./make-vhost.sh /var/www/mon-projet mon-site.local
```

---

### 2. `lm-clean.sh` - Maintenance Système

Un script de nettoyage conçu spécifiquement pour **Linux Mint** (et compatible Debian/Ubuntu). Il permet de libérer de l'espace disque en toute sécurité.

**Tâches effectuées :**
- 🧹 Vidage du cache APT et suppression des paquets orphelins.
- 🖼️ Nettoyage du cache des miniatures (thumbnails).
- 📂 Suppression des fichiers temporaires et vieux journaux (> 7 jours).
- 🗑️ Vidage de la corbeille utilisateur.
- 📊 Rapport d'espace disque avant et après.

**Utilisation :**
```bash
chmod +x lm-clean.sh
./lm-clean.sh
```

---

## 🛠️ Installation

Clonez simplement le dépôt et donnez les droits d'exécution aux scripts :

```bash
git clone https://github.com/tj-eddy/codeddy-tools.git
cd codeddy-tools
chmod +x *.sh
```

---

## 🤝 Contribution

Les suggestions et contributions sont les bienvenues ! N'hésitez pas à ouvrir une *Issue* ou à proposer une *Pull Request*.

## 🧔 Auteurs

- **Eddy** ([@tj-eddy](https://github.com/tj-eddy)) - Développeur Principal
- **Claude** - Assistant IA de conception

---

> Proposé par [TJ Eddy](https://github.com/tj-eddy)
