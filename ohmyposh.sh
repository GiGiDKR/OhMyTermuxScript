#!/bin/bash

# Commencer par clear et mise à jour des paquets
clear && pkg update -y

# Fonction pour installer gum
install_gum() {
  if ! command -v gum &> /dev/null; then
    echo "Installation de gum..."
    pkg install -y gum
  else
    echo "gum est déjà installé."
  fi
}

# Vérification des arguments pour ignorer l'installation de gum
USE_GUM=true
for arg in "$@"; do
  if [[ "$arg" == "--nogum" || "$arg" == "-ng" ]]; then
    USE_GUM=false
    break
  fi
done

# Fonction pour afficher la bannière avec une bordure et une largeur réduite
show_banner() {
    clear
    if $USE_GUM; then
        gum style \
            --foreground 212 \
            --border-foreground 212 \
            --align center \
            --width 25 \
            --margin "1 2" \
            "Oh-My-Termux" \
            "Oh-My-Posh"
    else
        echo "Oh-My-Termux"
        echo "Oh-My-Posh"
    fi
}

# Installation de gum si nécessaire
if $USE_GUM; then
  install_gum
fi

# Affichage de la bannière
show_banner

# Utilisation de gum pour confirmer l'installation de Oh-My-Posh
if $USE_GUM; then
    gum confirm "Installer Oh-My-Posh ?" || { echo "Installation annulée."; exit 0; }
fi

# Installer Oh My Posh via pkg
show_banner
echo "Installation de Oh-My-Posh via pkg..."
pkg install -y oh-my-posh

# Télécharger et installer la police DejaVu Sans Mono
show_banner
echo "Téléchargement de la police DejaVu Sans Mono..."
curl -fLo "$HOME/.termux/font.ttf" --create-dirs https://raw.githubusercontent.com/termux/termux-styling/master/app/src/main/assets/fonts/DejaVu-Sans-Mono.ttf

# Détection du shell
SHELL_NAME=$(basename "$SHELL")

# Définition du fichier de configuration en fonction du shell
case $SHELL_NAME in
  bash)
    CONFIG_FILE="$HOME/.bashrc"
    EXEC_CMD="exec bash"
    ;;
  zsh)
    CONFIG_FILE="$HOME/.zshrc"
    EXEC_CMD="exec zsh"
    ;;
  fish)
    CONFIG_FILE="$HOME/.config/fish/config.fish"
    EXEC_CMD="exec fish"
    ;;
  *)
    echo "Shell non supporté : $SHELL_NAME"
    exit 1
    ;;
esac

# Ligne à ajouter pour Oh My Posh
LINE_TO_ADD='eval "$(oh-my-posh init bash --config /data/data/com.termux/files/usr/share/oh-my-posh/themes/jandedobbeleer.omp.json)"'

# Vérifier si la ligne est déjà présente, sinon l'ajouter
if ! grep -qF "$LINE_TO_ADD" "$CONFIG_FILE"; then
  show_banner
  echo "Ajout de la configuration Oh-My-Posh au fichier $CONFIG_FILE"
  echo "$LINE_TO_ADD" >> "$CONFIG_FILE"
else
  echo "La configuration Oh-My-Posh est déjà présente dans $CONFIG_FILE"
fi

# Rechargement des paramètres de Termux
termux-reload-settings

clear
# Exécuter la commande exec appropriée pour recharger le shell
eval $EXEC_CMD

echo "Installation et configuration terminées."
