#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Validating editor plugins and extensions..."

# Test VS Code extensions
test_vscode_extensions() {
    if command_exists "code"; then
        echo "VS Code Extensions:"
        echo "-----------------"
        
        # Common development extensions
        local extensions=(
            # Languages and Frameworks
            "ms-python.python"            # Python
            "ms-python.vscode-pylance"    # Python Language Server
            "golang.go"                   # Go
            "redhat.java"                 # Java
            "vscjava.vscode-java-pack"    # Java Extension Pack
            "rust-lang.rust-analyzer"     # Rust
            "ms-vscode.cpptools"          # C/C++
            
            # Web Development
            "dbaeumer.vscode-eslint"      # ESLint
            "esbenp.prettier-vscode"      # Prettier
            "ritwickdey.LiveServer"       # Live Server
            "ms-azuretools.vscode-docker" # Docker
            
            # Git and Version Control
            "eamodio.gitlens"            # GitLens
            "mhutchie.git-graph"         # Git Graph
            
            # Themes and UI
            "dracula-theme.theme-dracula" # Dracula Theme
            "PKief.material-icon-theme"   # Material Icon Theme
            
            # Productivity
            "vscodevim.vim"              # Vim
            "ms-vsliveshare.vsliveshare" # Live Share
            "streetsidesoftware.code-spell-checker" # Code Spell Checker
        )
        
        local installed=0
        local total=${#extensions[@]}
        
        for ext in "${extensions[@]}"; do
            printf "%-40s: " "$ext"
            if code --list-extensions | grep -q "^${ext}$"; then
                echo -e "${GREEN}Installed${NC}"
                ((installed++))
            else
                echo -e "${YELLOW}Not installed${NC}"
            fi
        done
        
        echo
        echo "Extension Statistics:"
        echo "Total: $total"
        echo "Installed: $installed"
        echo "Coverage: $((installed * 100 / total))%"
    else
        log_warn "VS Code not installed, skipping extension checks"
    fi
}

# Test Neovim plugins
test_neovim_plugins() {
    if command_exists "nvim"; then
        echo -e "\nNeovim Plugins:"
        echo "--------------"
        
        # Check for plugin managers
        local plugin_manager=""
        if [ -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]; then
            plugin_manager="vim-plug"
        elif [ -d "$HOME/.config/nvim/bundle/neobundle.vim" ]; then
            plugin_manager="neobundle"
        elif [ -d "$HOME/.local/share/nvim/site/pack/packer" ]; then
            plugin_manager="packer"
        fi
        
        if [ -n "$plugin_manager" ]; then
            echo "Plugin Manager: $plugin_manager"
            
            # Check common plugin directories
            local plugin_dirs=(
                "$HOME/.local/share/nvim/plugged"
                "$HOME/.config/nvim/bundle"
                "$HOME/.local/share/nvim/site/pack/*/start"
            )
            
            local plugins_found=0
            for dir in "${plugin_dirs[@]}"; do
                if [ -d "$dir" ]; then
                    echo "Found plugins in: $dir"
                    plugins_found=$(( plugins_found + $(ls -1 "$dir" 2>/dev/null | wc -l) ))
                fi
            done
            
            echo "Total plugins found: $plugins_found"
        else
            log_warn "No plugin manager detected"
        fi
    else
        log_warn "Neovim not installed, skipping plugin checks"
    fi
}

# Test Sublime Text packages
test_sublime_packages() {
    if command_exists "subl"; then
        echo -e "\nSublime Text Packages:"
        echo "-------------------"
        
        local package_dir="$HOME/.config/sublime-text-3/Installed Packages"
        if [ -d "$package_dir" ]; then
            echo "Installed packages:"
            local packages_found=$(ls -1 "$package_dir" 2>/dev/null | wc -l)
            ls -1 "$package_dir" 2>/dev/null | sed 's/\.sublime-package//' | while read -r package; do
                echo "- $package"
            done
            echo "Total packages: $packages_found"
        else
            log_warn "No Sublime Text packages directory found"
        fi
    else
        log_warn "Sublime Text not installed, skipping package checks"
    fi
}

# Test Vim plugins
test_vim_plugins() {
    if command_exists "vim"; then
        echo -e "\nVim Plugins:"
        echo "-----------"
        
        # Check for plugin managers
        local plugin_manager=""
        if [ -f "$HOME/.vim/autoload/plug.vim" ]; then
            plugin_manager="vim-plug"
        elif [ -d "$HOME/.vim/bundle/Vundle.vim" ]; then
            plugin_manager="vundle"
        elif [ -f "$HOME/.vim/autoload/pathogen.vim" ]; then
            plugin_manager="pathogen"
        fi
        
        if [ -n "$plugin_manager" ]; then
            echo "Plugin Manager: $plugin_manager"
            
            # Check plugin directories
            local plugin_dirs=(
                "$HOME/.vim/plugged"
                "$HOME/.vim/bundle"
                "$HOME/.vim/pack/*/start"
            )
            
            local plugins_found=0
            for dir in "${plugin_dirs[@]}"; do
                if [ -d "$dir" ]; then
                    echo "Found plugins in: $dir"
                    plugins_found=$(( plugins_found + $(ls -1 "$dir" 2>/dev/null | wc -l) ))
                fi
            done
            
            echo "Total plugins found: $plugins_found"
        else
            log_warn "No Vim plugin manager detected"
        fi
    else
        log_warn "Vim not installed, skipping plugin checks"
    fi
}

# Check Language Server Protocol installations
test_lsp_servers() {
    echo -e "\nLanguage Server Protocol Support:"
    echo "-----------------------------"
    
    local lsp_servers=(
        "typescript-language-server"
        "pyls"
        "gopls"
        "rust-analyzer"
        "clangd"
        "jdtls"
        "bash-language-server"
    )
    
    local installed=0
    local total=${#lsp_servers[@]}
    
    for server in "${lsp_servers[@]}"; do
        printf "%-25s: " "$server"
        if command_exists "$server"; then
            echo -e "${GREEN}Installed${NC}"
            ((installed++))
        else
            echo -e "${YELLOW}Not installed${NC}"
        fi
    done
    
    echo
    echo "LSP Server Statistics:"
    echo "Total: $total"
    echo "Installed: $installed"
    echo "Coverage: $((installed * 100 / total))%"
}

# Run all tests
test_vscode_extensions
test_neovim_plugins
test_sublime_packages
test_vim_plugins
test_lsp_servers

log_info "Editor plugin validation completed!"