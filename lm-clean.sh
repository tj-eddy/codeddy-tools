#!/bin/bash

# ============================================
# Script de nettoyage pour Linux Mint
# Nom: lm-clean.sh
# ============================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher un titre
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Fonction pour afficher le résultat
print_result() {
    echo -e "${GREEN}✓${NC} $1"
}

# Vérifier si le script est exécuté avec sudo pour certaines opérations
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Note: Certaines opérations nécessitent les privilèges sudo.${NC}"
        USE_SUDO="sudo"
    else
        USE_SUDO=""
    fi
}

# Fonction pour obtenir l'espace disque avant
get_disk_space() {
    df -h / | awk 'NR==2 {print $4}'
}

# ============================================
# DÉBUT DU SCRIPT
# ============================================

print_header "NETTOYAGE LINUX MINT"
echo "Démarrage du nettoyage système..."

# Vérification sudo
check_sudo

# Espace disponible avant nettoyage
SPACE_BEFORE=$(get_disk_space)
echo -e "Espace disponible avant nettoyage: ${YELLOW}$SPACE_BEFORE${NC}"

# ============================================
# 1. Nettoyage du cache APT
# ============================================
print_header "1. Nettoyage du cache APT"
CACHE_SIZE=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1)
echo "Taille actuelle du cache APT: $CACHE_SIZE"

$USE_SUDO apt clean -y 2>/dev/null
if [ $? -eq 0 ]; then
    print_result "Cache APT nettoyé"
else
    echo -e "${RED}✗${NC} Erreur lors du nettoyage du cache APT"
fi

# ============================================
# 2. Suppression des paquets orphelins
# ============================================
print_header "2. Suppression des paquets orphelins"
$USE_SUDO apt autoremove -y 2>/dev/null
if [ $? -eq 0 ]; then
    print_result "Paquets orphelins supprimés"
else
    echo -e "${RED}✗${NC} Erreur lors de la suppression des paquets orphelins"
fi

# ============================================
# 3. Nettoyage du cache des miniatures
# ============================================
print_header "3. Nettoyage du cache des miniatures"
if [ -d "$HOME/.cache/thumbnails" ]; then
    THUMB_SIZE=$(du -sh $HOME/.cache/thumbnails 2>/dev/null | cut -f1)
    echo "Taille du cache de miniatures: $THUMB_SIZE"
    rm -rf $HOME/.cache/thumbnails/*
    print_result "Cache des miniatures nettoyé"
else
    echo "Aucun cache de miniatures trouvé"
fi

# ============================================
# 4. Nettoyage du cache utilisateur
# ============================================
print_header "4. Nettoyage du cache utilisateur"
if [ -d "$HOME/.cache" ]; then
    # Exclure certains dossiers importants
    find $HOME/.cache -type f -atime +30 -delete 2>/dev/null
    print_result "Fichiers de cache anciens (>30 jours) supprimés"
else
    echo "Aucun cache utilisateur trouvé"
fi

# ============================================
# 5. Nettoyage des journaux système
# ============================================
print_header "5. Nettoyage des journaux système (>7 jours)"
$USE_SUDO journalctl --vacuum-time=7d 2>/dev/null
if [ $? -eq 0 ]; then
    print_result "Journaux système nettoyés"
else
    echo -e "${YELLOW}Note: journalctl non disponible ou nécessite sudo${NC}"
fi

# ============================================
# 6. Nettoyage de la corbeille
# ============================================
print_header "6. Nettoyage de la corbeille"
if [ -d "$HOME/.local/share/Trash" ]; then
    TRASH_SIZE=$(du -sh $HOME/.local/share/Trash 2>/dev/null | cut -f1)
    echo "Taille de la corbeille: $TRASH_SIZE"
    rm -rf $HOME/.local/share/Trash/files/*
    rm -rf $HOME/.local/share/Trash/info/*
    print_result "Corbeille vidée"
else
    echo "Aucune corbeille trouvée"
fi

# ============================================
# 7. Nettoyage des fichiers temporaires
# ============================================
print_header "7. Nettoyage des fichiers temporaires"
if [ -d "/tmp" ]; then
    $USE_SUDO find /tmp -type f -atime +7 -delete 2>/dev/null
    print_result "Fichiers temporaires anciens supprimés"
fi

# ============================================
# RÉSUMÉ FINAL
# ============================================
print_header "RÉSUMÉ DU NETTOYAGE"

# Espace disponible après nettoyage
SPACE_AFTER=$(get_disk_space)
echo -e "Espace disponible avant: ${YELLOW}$SPACE_BEFORE${NC}"
echo -e "Espace disponible après: ${GREEN}$SPACE_AFTER${NC}"

echo -e "\n${GREEN}Nettoyage terminé avec succès!${NC}"
echo -e "${BLUE}Conseil:${NC} Exécutez ce script régulièrement pour maintenir votre système propre.\n"
