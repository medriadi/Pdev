#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Validating editor installations..."

# Test VS Code
test_vscode() {
    if command_exists "code"; then
        if code --version && \
           code --list-extensions >/dev/null 2>&1; then
            # Test common extensions
            local missing_extensions=false
            local extensions=(
                "ms-python.python"
                "dbaeumer.vscode-eslint"
                "esbenp.prettier-vscode"
                "redhat.java"
                "ms-azuretools.vscode-docker"
            )
            
            for ext in "${extensions[@]}"; do
                if ! code --list-extensions | grep -q "^${ext}$"; then
                    log_warn "VS Code extension not installed: $ext"
                    missing_extensions=true
                fi
            done
            
            if [ "$missing_extensions" = false ]; then
                log_info "VS Code: OK (with recommended extensions)"
            else
                log_info "VS Code: OK (some recommended extensions missing)"
            fi
            return 0
        fi
    fi
    log_error "VS Code validation failed"
    return 1
}

# Test Neovim
test_neovim() {
    if command_exists "nvim"; then
        if nvim --version; then
            # Check for common plugins and configurations
            if [ -d "$HOME/.config/nvim" ] && [ -f "$HOME/.config/nvim/init.vim" ]; then
                log_info "Neovim: OK (with configuration)"
            else
                log_info "Neovim: OK (basic installation)"
            fi
            return 0
        fi
    fi
    log_error "Neovim validation failed"
    return 1
}

# Test Sublime Text
test_sublime() {
    if command_exists "subl"; then
        if subl --version >/dev/null 2>&1; then
            # Check for Package Control
            if [ -d "$HOME/.config/sublime-text-3/Installed Packages/Package Control.sublime-package" ]; then
                log_info "Sublime Text: OK (with Package Control)"
            else
                log_info "Sublime Text: OK (basic installation)"
            fi
            return 0
        fi
    fi
    log_error "Sublime Text validation failed"
    return 1
}

# Test JetBrains IDEs
test_jetbrains() {
    local ide_found=false
    local ides=(
        "idea"      # IntelliJ IDEA
        "pycharm"   # PyCharm
        "webstorm"  # WebStorm
        "goland"    # GoLand
    )
    
    for ide in "${ides[@]}"; do
        if command_exists "$ide"; then
            ide_found=true
            if $ide --version >/dev/null 2>&1; then
                log_info "JetBrains $ide: OK"
            else
                log_warn "JetBrains $ide: Installation found but may have issues"
            fi
        fi
    done
    
    if [ "$ide_found" = true ]; then
        return 0
    fi
    
    log_info "No JetBrains IDEs found (optional)"
    return 0
}

# Test Vim
test_vim() {
    if command_exists "vim"; then
        if vim --version; then
            # Check for .vimrc and plugins
            if [ -f "$HOME/.vimrc" ]; then
                if [ -d "$HOME/.vim/bundle" ] || [ -d "$HOME/.vim/plugged" ]; then
                    log_info "Vim: OK (with plugins)"
                else
                    log_info "Vim: OK (with configuration)"
                fi
            else
                log_info "Vim: OK (basic installation)"
            fi
            return 0
        fi
    fi
    log_error "Vim validation failed"
    return 1
}

# Test Language Server Protocol support
test_lsp() {
    local lsp_ok=true
    
    # Check common language servers
    echo "Testing Language Server Protocol support:"
    
    # TypeScript/JavaScript
    if command_exists "typescript-language-server"; then
        log_info "TypeScript LSP: OK"
    else
        log_warn "TypeScript LSP not found"
        lsp_ok=false
    fi
    
    # Python
    if command_exists "pyls" || command_exists "pylsp"; then
        log_info "Python LSP: OK"
    else
        log_warn "Python LSP not found"
        lsp_ok=false
    fi
    
    # Java
    if command_exists "jdtls"; then
        log_info "Java LSP: OK"
    else
        log_warn "Java LSP not found"
        lsp_ok=false
    fi
    
    # Go
    if command_exists "gopls"; then
        log_info "Go LSP: OK"
    else
        log_warn "Go LSP not found"
        lsp_ok=false
    fi
    
    return $lsp_ok
}

# Test Git integration
test_git_integration() {
    local tools_ok=true
    
    echo "Testing Git integration tools:"
    
    # Git GUI tools
    if command_exists "gitk"; then
        log_info "Gitk: OK"
    else
        tools_ok=false
    fi
    
    if command_exists "git-gui"; then
        log_info "Git GUI: OK"
    else
        tools_ok=false
    fi
    
    # Meld (diff tool)
    if command_exists "meld"; then
        log_info "Meld: OK"
    else
        tools_ok=false
    fi
    
    return $tools_ok
}

# Run all tests
test_vscode
test_neovim
test_sublime
test_jetbrains
test_vim
test_lsp
test_git_integration

log_info "Editor validation completed!"