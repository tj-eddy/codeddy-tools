# Tools

Collection de scripts d'automatisation pour le developpement web sur Linux.

---

## Structure du projet

```
Tools/
├── make-vhost.sh                       # Creation de Virtual Hosts Apache/Nginx
├── lm-clean.sh                         # Nettoyage systeme Linux Mint
└── DDEV/
    ├── install-ddev-docker.sh          # Installation Docker + DDEV
    ├── install-wordpress-ddev.sh       # Projet WordPress avec DDEV
    ├── install-prestashop-ddev.sh      # Projet PrestaShop avec DDEV
    ├── install-symfony-ddev.sh         # Projet Symfony avec DDEV
    ├── transform-lamp-to-ddev.sh       # Migration LAMP vers DDEV
    ├── README.md                       # Documentation detaillee DDEV
    └── EXEMPLES-CONCRETS.md            # Scenarios d'utilisation pas a pas
```

---

## Scripts principaux

### `make-vhost.sh`

Automatise la creation de Virtual Hosts pour **Apache** et **Nginx** sur Linux.

- Detection automatique du type de projet (Symfony, PrestaShop, WordPress, generique)
- Configuration PHP-FPM automatique
- Gestion des permissions adaptee au framework
- Ajout automatique dans `/etc/hosts`
- Test de configuration et redemarrage du serveur

```bash
sudo ./make-vhost.sh /var/www/mon-projet
sudo ./make-vhost.sh /var/www/mon-projet mon-site.dev
```

**Prerequis :** Linux (Debian/Ubuntu ou RHEL), Apache ou Nginx installe, PHP, droits sudo.

---

### `lm-clean.sh`

Script de nettoyage systeme pour **Linux Mint**. Libere de l'espace disque en nettoyant :

1. Cache APT
2. Paquets orphelins
3. Cache des miniatures
4. Cache utilisateur (fichiers > 30 jours)
5. Journaux systeme (> 7 jours)
6. Corbeille
7. Fichiers temporaires (> 7 jours)

Affiche l'espace disque avant/apres le nettoyage.

```bash
chmod +x lm-clean.sh
./lm-clean.sh
```

---

## Dossier DDEV

Scripts d'installation et de configuration de projets web avec [DDEV](https://ddev.readthedocs.io/) et Docker.

### `DDEV/install-ddev-docker.sh`

Installation complete de **Docker Engine** et **DDEV** sur Linux Mint :
- Docker Engine + Docker Compose
- DDEV
- mkcert (HTTPS local)
- Configuration des permissions utilisateur

```bash
bash DDEV/install-ddev-docker.sh
# Deconnexion/reconnexion requise apres execution
```

### `DDEV/install-wordpress-ddev.sh`

Cree un projet **WordPress** DDEV avec installation automatique :
- Telechargement WordPress (FR)
- Configuration base de donnees
- Installation WP-CLI
- Theme, permaliens et permissions configures

```bash
bash DDEV/install-wordpress-ddev.sh
```

### `DDEV/install-prestashop-ddev.sh`

Cree un projet **PrestaShop** DDEV :
- Versions supportees : 9.0.3 (Composer), 8.2.4, 8.1.7, 1.7.8.11
- Installation via Composer (9.x) ou ZIP (8.x, 1.7.x)
- Configuration des permissions et de la base de donnees
- Installation finale via l'interface web

```bash
bash DDEV/install-prestashop-ddev.sh
```

### `DDEV/install-symfony-ddev.sh`

Cree un projet **Symfony** DDEV :
- Types : webapp complete, API REST, skeleton minimal, website-skeleton
- Version Symfony configurable
- Outils dev inclus (MakerBundle, Profiler)
- Hook post-start pour cache warmup

```bash
bash DDEV/install-symfony-ddev.sh
```

### `DDEV/transform-lamp-to-ddev.sh`

Migre un projet **LAMP existant** vers DDEV :
- Detection automatique : WordPress, PrestaShop, Symfony, Laravel, Drupal, PHP generique
- Sauvegarde complete du projet
- Export/import de la base de donnees MySQL
- Mise a jour de la configuration (wp-config, .env, etc.)

```bash
cd /var/www/mon-projet-lamp
bash /chemin/vers/DDEV/transform-lamp-to-ddev.sh
```

### Documentation DDEV

- [DDEV/README.md](DDEV/README.md) : Documentation complete (commandes, configuration, depannage)
- [DDEV/EXEMPLES-CONCRETS.md](DDEV/EXEMPLES-CONCRETS.md) : 7 scenarios d'utilisation detailles pas a pas

---

## Contributeurs

- **Eddy** (Developpeur Principal)
- **Claude** (Assistant IA)

> Propose par [TJ Eddy](https://github.com/tj-eddy)
