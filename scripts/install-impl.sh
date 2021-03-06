#!/usr/bin/env bash

set -e

######################## UTILS BEGIN ########################

setup_color() {
    # Only use colors if connected to a terminal
    if [ -t 1 ]; then
        RED=$(printf '\033[91m')
        GREEN=$(printf '\033[92m')
        YELLOW=$(printf '\033[93m')
        BLUE=$(printf '\033[94m')
        BOLD=$(printf '\033[1m')
        RESET=$(printf '\033[m')
    else
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        BOLD=""
        RESET=""
    fi
}

command_exists() {
    command -v "$@" >/dev/null 2>&1
}

check_command() {
    if ! command_exists $@;
    then
        error "$@ is not installed"
        exit 1
    fi
}

error() {
    echo "${RED}[ERRO]${RESET}: $@" >&2
}

warn() {
    echo "${YELLOW}[WARN]${RESET}: $@" >&1
}

info() {
    echo "${BLUE}[INFO]${RESET}: $@" >&1
}

ok() {
    echo "${GREEN}[ OK ]${RESET}: $@" >&1
}

yes_no() {
    if [[ $# -eq 0 ]];
    then
        error "invalid argument for prompt, \$# is 0"
        exit 1
    fi
    
    text="$1"
    answer_prompt=""
    default_answer=""
    
    if [[ -n $2 ]]
    then
        case $2 in
            [Yy]* ) 
                answer_prompt="[Y/n]"
                default_answer="y"
                ;;
            [Nn]* ) 
                answer_prompt="[y/N]"
                default_answer="n"
                ;;
            * ) 
                error "invalid argument for prompt, \$2 must be [Y,y,N,n]"
                exit 1
                ;;
        esac
    fi
    
    while true; do
        read -p "$text $answer_prompt " yn
        case $yn in
            [Yy]* ) 
                echo "y"
                return
                ;;
            [Nn]* ) 
                echo "n"
                return
                ;;
            * )
                if [[ -z $yn ]];
                then
                    echo "$default_answer"
                    return
                fi
                ;;
        esac
    done
}

######################## UTILS END ########################

######################## VARIABLES BEGIN ########################

_LOCAL_REPO="$(dirname "${BASH_SOURCE[0]}")"
_LOCAL_REPO="$(realpath "${_LOCAL_REPO}/..")"
echo $_LOCAL_REPO

_ZSH_CUSTOM=""
_FONTS_DIR="$_LOCAL_REPO/fonts"
_DOTFILES_DIR="$_LOCAL_REPO/dotfiles"

_INSTALL_ZSH_THEME_SCRIPT="$_LOCAL_REPO/scripts/install-zsh-theme.py"

######################## VARIABLES END ########################

check_oh_my_zsh() {  
    if [[ -z "$_ZSH_CUSTOM" ]];
    then
        error "Oh-my-zsh custom themes directory is empty"
        exit 1
    fi

    # if [[ ! -d "$_ZSH_CUSTOM" ]];
    # then
    #     error "Oh-my-zsh custom themes directory not exists"
    #     exit 1
    # fi
}

select_theme() {
    PS3='Please enter theme: '
    options=("LazyMechanic" "Powerlevel10k (lean)" "Powerlevel10k (classic)" "Powerlevel10k (rainbow)" "Default (robbyrussell)")
    select opt in "${options[@]}"
    do
        case $opt in
            "LazyMechanic")
                echo "lazymechanic"
                return
                ;;
            "Powerlevel10k (lean)")
                echo "p10klean"
                return
                ;;
            "Powerlevel10k (classic)")
                echo "p10kclassic"
                return
                ;;
            "Powerlevel10k (rainbow)")
                echo "p10krainbow"
                return
                ;;
            "Default (robbyrussell)")
                echo "default"
                return
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
}

install_zsh_theme() {
    info "Start install zsh theme..."
    
    theme=$(select_theme)
    python3 \
        "$_INSTALL_ZSH_THEME_SCRIPT" \
        --zsh-custom "$_ZSH_CUSTOM" \
        "$theme"
    
    ok "Done!"
    info "Start zsh session and call 'source ~/.zshrc'"
}

install_fonts() {
    info "Start install fonts..."
    
    # Check if need setup custom fonts
    answer=$(yes_no "Install custom fonts?" "y")
    if [ "$answer" == "y" ];
    then
        local_fonts_dir="$HOME/.local/share/fonts"
        mkdir -p "$local_fonts_dir"
        
        info "Font files to be installed:"
        for f in "$_FONTS_DIR"/*
        do
            echo " - $f"
        done

        info "Destination directory: $local_fonts_dir"
        
        info "Install fonts"
        cp -r "$_FONTS_DIR/." "$local_fonts_dir/"

        ok "Done!"
    else
        ok "Do nothing"
        return
    fi
}

install_dotfiles() {
    info "Copy dotfiles"
    local_dfiles_dir="$HOME"       
    cp -r "$_DOTFILES_DIR/." "$local_dfiles_dir/"
    ok "Done!"
}

install_dependencies() {
    info "Install dependencies"

    sudo bash -c 'pacman -Syu'
    sudo bash -c 'pacman -S yay'
    yay -S                          \
        base-devel                  \
        zsh                         \
        bat                         \
        exa                         \
        feh                         \
        yad                         \
        rofi                        \
        dmenu                       \
        dunst                       \
        picom                       \
        polybar                     \
        xdotool                     \
        autorandr                   \
        playerctl                   \
        lxappearance-gtk3           \
        i3-gaps                     \
        kitty                       \
        spotify                     \
        discord                     \
        vk-messenger                \
        telegram-desktop            \
        jetbrains-toolbox

    ok "Done!"

    info "Install oh-my-zsh"
    # If oh-my-zsh already exists
    if [ -d "$ZSH" ];
    then
        answer=$(yes_no "Oh my zsh already exists. Reinstall it?" "y")
        if [ "$answer" == "y" ];
        then
            info "Uninstall oh-my-zsh"
            env ZSH="$ZSH" sh "$ZSH/tools/uninstall.sh"
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            ok "Done!"
        fi
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    ok "Done!"

    info "Change shell"
    chsh -s $(which zsh)
    ok "Done!"

    return
}

select_action() {
    PS3='Please enter action: '
    options=("Install zsh theme" "Install fonts" "Install dotfiles" "Install dependencies" "Full installation (dependencies, dotfiles, fonts, zsh theme)" "Exit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Install zsh theme")
                echo "zsh"
                return
                ;;
            "Install fonts")
                echo "fonts"
                return
                ;;
            "Install dotfiles")
                echo "dotfiles"
                return
                ;;
            "Install dependencies")
                echo "dependencies"
                return
                ;;
            "Full installation (dependencies, dotfiles, fonts, zsh theme)")
                echo "full"
                return
                ;;
            "Exit")
                echo "exit"
                return
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
}

main_loop() {
    while true
    do
        action=$(select_action)
        case $action in
            "zsh")
                install_zsh_theme
                ;;
            "fonts")
                install_fonts
                ;;
            "dotfiles")
                install_dotfiles
                return
                ;;
            "dependencies")
                install_dependencies
                return
                ;;
            "full")
                install_dotfiles
                install_dependencies
                install_fonts
                install_zsh_theme
                return
                ;;
            "exit")
                return
                ;;
        esac
    done
}

main() {
    setup_color

    # Check commands
    check_command git
    check_command sed
    check_command source
    check_command python3
    check_command pacman
    
    # If no has argument
    if [[ $# != 1 ]];
    then
        error "invalid argument, 1st argument must be \$ZSH_CUSTOM"
    fi

    _ZSH_CUSTOM="$1"

    # Check if zsh custom dir exists
    check_oh_my_zsh

    main_loop
}

main $@