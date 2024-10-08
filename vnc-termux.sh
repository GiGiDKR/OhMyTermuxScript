#!/data/data/com.termux/files/usr/bin/bash

# Vérifier si le script est exécuté dans Termux
if [ ! -d /data/data/com.termux ]; then
    echo "Ce script doit être exécuté dans Termux."
    exit 1
fi

# Mise à jour des paquets Termux
echo "Mise à jour des paquets Termux..."
clear && pkg update -y

# Variables pour déterminer si gum doit être utilisé et si une désinstallation doit être effectuée
USE_GUM=false
UNINSTALL=false

# Vérification des arguments
for arg in "$@"; do
    case $arg in
        --gum|-g)
            USE_GUM=true
            shift
            ;;
        --uninstall|-u)
            UNINSTALL=true
            shift
            ;;
    esac
done

# Fonction pour vérifier et installer gum
check_and_install_gum() {
    if $USE_GUM && ! command -v gum &> /dev/null; then
        echo "Installation de gum..."
        pkg install gum -y
    fi
}

# Fonction pour afficher la bannière
show_banner() {
    clear
    if $USE_GUM; then
        gum style \
            --foreground 212 \
            --border-foreground 212 \
            --border double \
            --align center \
            --width 40 \
            --margin "1 2" \
            --padding "1 1" \
            "Oh-My-Termux" \
            "     VNC     " \
            ""
    else
        echo -e "\e[1;34mOh-My-Termux\e[0m"
        echo -e "\e[1;35m     VNC      \e[0m"
        echo
    fi
}

install_package() {
    local package=$1
    if $USE_GUM; then
        if ! gum spin --spinner dot --title "Installation de $package ..." -- pkg install $package -y; then
            echo "Erreur lors de l'installation de $package"
            exit 1
        fi
    else
        if ! pkg install $package -y; then
            echo "Erreur lors de l'installation de $package"
            exit 1
        fi
    fi
}

# Fonction pour désinstaller les modifications
uninstall_changes() {
    echo "Désinstallation de VNC et suppression des modifications..."
    if $USE_GUM; then
        gum spin --spinner dot --title "Désinstallation de VNC ..." -- pkg uninstall tigervnc -y
    else
        pkg uninstall tigervnc -y
    fi

    # Supprimer les alias de configuration
    sed -i '/alias startvnc/d' "$CONFIG_FILE"
    sed -i '/alias stopvnc/d' "$CONFIG_FILE"
    echo "Modifications désinstallées avec succès."
}

# Détecter le shell actif
SHELL_NAME=$(basename $SHELL)

# Définir le fichier de configuration en fonction du shell
case $SHELL_NAME in
    bash)
        CONFIG_FILE="$HOME/.bashrc"
    ;;
    zsh)
        CONFIG_FILE="$HOME/.zshrc"
    ;;
    fish)
        CONFIG_FILE="$HOME/.config/fish/config.fish"
    ;;
    *)
        echo "Shell non supporté : $SHELL_NAME"
        exit 1
    ;;
esac

# Si le paramètre de désinstallation est fourni, exécuter la désinstallation et quitter
if $UNINSTALL; then
    uninstall_changes
    exit 0
fi

# Appeler la fonction pour vérifier et installer gum
check_and_install_gum

# Afficher la bannière
show_banner

# Installer le package vnc
install_package tigervnc

# Exécuter vnc pour la première fois afin que l'utilisateur puisse définir un mot de passe
if ! vncserver && vncserver -kill :1; then
    echo "Erreur lors de la configuration initiale de VNC"
    exit 1
fi

# Ajouter un alias pour démarrer le serveur vnc
echo 'alias startvnc="vncserver -xstartup ../usr/bin/startxfce4 -listen tcp :1 && rm -r /data/data/com.termux/files/usr/tmp && mkdir /data/data/com.termux/files/usr/tmp"' >> $CONFIG_FILE

# Ajouter un alias pour arrêter le serveur vnc
echo 'alias stopvnc="vncserver -kill :1"' >> $CONFIG_FILE

# Recharger le fichier de configuration pour rendre les alias disponibles dans la session actuelle
if [ "$SHELL_NAME" = "fish" ]; then
    source $CONFIG_FILE
else
    . $CONFIG_FILE
fi