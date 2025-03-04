#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Installing Utility Tools..."

# Update package manager
update_pkg_manager

# Essential developer utilities
BASE_UTILS=(
    "htop"
    "tmux"
    "jq"
    "tree"
    "neofetch"
    "net-tools"
    "nmap"
    "zip"
    "unzip"
    "git-lfs"
    "ripgrep"
    "fzf"
    "shellcheck"
    "moreutils"
)

# Optional development utilities
EXTRA_UTILS=(
    "tig"              # Text-mode interface for Git
    "ncdu"             # NCurses disk usage
    "tldr"             # Simplified man pages
    "bat"              # Cat clone with syntax highlighting
    "exa"              # Modern replacement for ls
    "fd-find"          # Simple, fast alternative to find
    "httpie"           # User-friendly cURL alternative
    "meld"             # Visual diff and merge tool
    "cloc"             # Count lines of code
    "asciinema"        # Terminal session recorder
)

# Install base utilities
for util in "${BASE_UTILS[@]}"; do
    install_package "$util"
done

# Install extra utilities if configured
if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
    for util in "${EXTRA_UTILS[@]}"; do
        install_package "$util"
    done
fi

# Install modern shell utilities
install_modern_utils() {
    # Install starship prompt
    if ! command_exists "starship"; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
    fi
    
    # Install zoxide (smart cd command)
    if ! command_exists "zoxide"; then
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
    fi
    
    # Install delta (better git diffs)
    if ! command_exists "delta"; then
        install_package "git-delta"
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
    fi
}

# Install system monitoring tools
install_monitoring_utils() {
    if [ "$(get_config_value INSTALL_MONITORING true)" = "true" ]; then
        # Install system monitoring tools
        install_package "sysstat"
        install_package "iotop"
        install_package "nload"
        install_package "nethogs"
        install_package "glances"
        
        # Install bottom (modern system monitor)
        if ! command_exists "btm"; then
            curl -LO https://github.com/ClementTsang/bottom/releases/latest/download/bottom_amd64.deb
            dpkg -i bottom_amd64.deb
            rm bottom_amd64.deb
        fi
    fi
}

# Install network utilities
install_network_utils() {
    NETWORK_UTILS=(
        "mtr"           # Traceroute and ping combined
        "iperf3"        # Network performance tool
        "ncat"          # Enhanced netcat
        "tcpdump"       # Network packet analyzer
        "wireshark"     # Network protocol analyzer
        "speedtest-cli" # Internet speed test
    )
    
    for util in "${NETWORK_UTILS[@]}"; do
        install_package "$util"
    done
}

# Install productivity tools
install_productivity_tools() {
    # Install task management
    if ! command_exists "task"; then
        install_package "taskwarrior"
    fi
    
    # Install note-taking tools
    install_package "mdbook"  # Markdown book creator
    
    # Install terminal multiplexer configuration
    if [ -f "$HOME/.tmux.conf" ]; then
        cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup"
    fi
    
    # Configure tmux with better defaults
    cat > "$HOME/.tmux.conf" << 'EOF'
# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Enable true color support
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Increase history limit
set -g history-limit 50000

# Use vi keys in copy mode
setw -g mode-keys vi

# Better split pane shortcuts
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Reload config with r
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Better status bar
set -g status-style bg=default
set -g status-left "#[fg=green]#H #[fg=black]• #[fg=green,bright]#(uname -r)#[default]"
set -g status-right "#[fg=green,bg=default,bright]#(tmux-mem-cpu-load) #[fg=red,dim,bg=default]#(uptime | cut -f 4-5 -d ' ' | cut -f 1 -d ',') #[fg=white,bg=default]%a%l:%M:%S %p#[default] #[fg=blue]%Y-%m-%d"
EOF
}

# Install git utilities and configure git
setup_git() {
    # Install git-extras
    install_package "git-extras"
    
    # Configure git with better defaults if not already configured
    if [ ! -f "$HOME/.gitconfig" ]; then
        git config --global color.ui true
        git config --global core.editor "$(get_config_value DEFAULT_EDITOR vim)"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        git config --global fetch.prune true
        
        # Configure git aliases
        git config --global alias.st status
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.unstage 'reset HEAD --'
        git config --global alias.last 'log -1 HEAD'
        git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    fi
}

# Main installation
install_modern_utils
install_monitoring_utils
install_network_utils
install_productivity_tools
setup_git

# Create useful aliases
cat >> "$HOME/.bashrc" << 'EOF'

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias gt='cd $(git rev-parse --show-toplevel)'
alias k='kubectl'
alias d='docker'
alias dc='docker-compose'
alias tf='terraform'
alias g='git'
alias vim='nvim'

# Enhanced commands (if installed)
if command -v exa &> /dev/null; then
    alias ls='exa'
    alias ll='exa -l'
    alias la='exa -la'
    alias lt='exa --tree'
fi

if command -v bat &> /dev/null; then
    alias cat='bat'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

# Useful functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
EOF

log_info "Utility Tools installation completed!"