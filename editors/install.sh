#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Installing Code Editors..."

# Update package manager
update_pkg_manager

# VSCode Extensions to install if enabled
VSCODE_EXTENSIONS=(
    # Languages support
    "ms-python.python"
    "golang.go"
    "rust-lang.rust-analyzer"
    "redhat.java"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    
    # Containers/Cloud
    "ms-azuretools.vscode-docker"
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "hashicorp.terraform"
    
    # Database tools
    "cweijan.vscode-postgresql-client2"
    "mongodb.mongodb-vscode"
    "mtxr.sqltools"
    
    # Git tools
    "eamodio.gitlens"
    "mhutchie.git-graph"
    
    # Theme and UI
    "PKief.material-icon-theme"
    "dracula-theme.theme-dracula"
)

# Install Visual Studio Code
install_vscode() {
    if ! command_exists "code"; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode.list
        update_pkg_manager
        install_package "code"
        
        # Install extensions if configured
        if [ "$(get_config_value INSTALL_VSCODE_EXTENSIONS true)" = "true" ]; then
            log_info "Installing VSCode extensions..."
            for ext in "${VSCODE_EXTENSIONS[@]}"; do
                code --install-extension "$ext" --force
            done
        fi
    fi
}

# Install Neovim with configuration
install_neovim() {
    if ! command_exists "nvim"; then
        install_package "neovim"
        
        # Install vim-plug
        sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        
        # Setup Neovim configuration based on preference
        local nvim_config=$(get_config_value "NEOVIM_CONFIG" "basic")
        local config_dir="$HOME/.config/nvim"
        ensure_dir "$config_dir"
        
        case $nvim_config in
            "basic")
                # Basic configuration for Neovim
                cat > "$config_dir/init.vim" << 'EOF'
set number
set relativenumber
set expandtab
set tabstop=4
set shiftwidth=4
set smartindent
set mouse=a
set clipboard+=unnamedplus

call plug#begin()
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

" Key mappings
nnoremap <C-n> :NERDTreeToggle<CR>
EOF
                ;;
            "advanced")
                # More advanced configuration with LSP support
                cat > "$config_dir/init.vim" << 'EOF'
set number
set relativenumber
set expandtab
set tabstop=4
set shiftwidth=4
set smartindent
set mouse=a
set clipboard+=unnamedplus
set termguicolors

call plug#begin()
" Essential plugins
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" LSP and completion
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'L3MON4D3/LuaSnip'

" Telescope
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

" Theme
Plug 'dracula/vim', { 'as': 'dracula' }
call plug#end()

" Theme setup
colorscheme dracula

" Key mappings
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-p> :Telescope find_files<CR>
nnoremap <C-f> :Telescope live_grep<CR>
EOF
                ;;
        esac
        
        # Install plugins
        nvim --headless +PlugInstall +qall
    fi
}

# Install Sublime Text
install_sublime() {
    if ! command_exists "subl"; then
        curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor -o /usr/share/keyrings/sublime-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/sublime-archive-keyring.gpg] https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
        update_pkg_manager
        install_package "sublime-text"
    fi
}

# Install JetBrains Toolbox
install_jetbrains_toolbox() {
    if [ ! -d "/opt/jetbrains-toolbox" ]; then
        TOOLBOX_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | jq -r '.TBA[0].downloads.linux.link')
        curl -fsSL "$TOOLBOX_URL" -o jetbrains-toolbox.tar.gz
        tar -xzf jetbrains-toolbox.tar.gz
        mv jetbrains-toolbox-*/jetbrains-toolbox /opt/jetbrains-toolbox
        rm -rf jetbrains-toolbox-* jetbrains-toolbox.tar.gz
    fi
}

# Install editors based on configuration
DEFAULT_EDITOR=$(get_config_value "DEFAULT_EDITOR" "vscode")

# Always install the default editor
case $DEFAULT_EDITOR in
    "vscode") install_vscode ;;
    "neovim") install_neovim ;;
    "sublime") install_sublime ;;
    *) log_error "Invalid default editor: $DEFAULT_EDITOR" ;;
esac

# Ask for additional editors
read -p "Would you like to install additional editors? [y/N] " install_more
if [[ $install_more =~ ^[Yy]$ ]]; then
    echo "Select additional editors to install:"
    echo "1) Visual Studio Code"
    echo "2) Neovim"
    echo "3) Sublime Text"
    echo "4) JetBrains Toolbox"
    read -p "Enter numbers (space-separated): " selections
    
    for selection in $selections; do
        case $selection in
            1) [ "$DEFAULT_EDITOR" != "vscode" ] && install_vscode ;;
            2) [ "$DEFAULT_EDITOR" != "neovim" ] && install_neovim ;;
            3) [ "$DEFAULT_EDITOR" != "sublime" ] && install_sublime ;;
            4) install_jetbrains_toolbox ;;
            *) log_warn "Invalid selection: $selection" ;;
        esac
    done
fi

log_info "Code Editors installation completed!"