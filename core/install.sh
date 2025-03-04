#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Installing Core Development Tools..."

# Update system if configured
update_system

# Setup swap if configured
setup_swap

# Essential build tools and compilers
CORE_PACKAGES=(
    "git"
    "build-essential"
    "gcc"
    "g++"
    "make"
    "cmake"
    "ninja-build"
    "autoconf"
    "automake"
    "pkg-config"
    "libtool"
    "bison"
    "flex"
    "gdb"
    "valgrind"
    "strace"
    "ltrace"
)

# Install core packages
for package in "${CORE_PACKAGES[@]}"; do
    install_package "$package"
done

# Install additional development libraries
DEV_LIBS=(
    "libssl-dev"
    "libcurl4-openssl-dev"
    "libxml2-dev"
    "libsqlite3-dev"
    "zlib1g-dev"
    "libbz2-dev"
    "libreadline-dev"
    "libffi-dev"
    "liblzma-dev"
    "libncurses5-dev"
    "libncursesw5-dev"
    "xz-utils"
    "tk-dev"
)

# Install development libraries
if [ "$(get_config_value INSTALL_RECOMMENDED_PACKAGES true)" = "true" ]; then
    for lib in "${DEV_LIBS[@]}"; do
        install_package "$lib"
    done
fi

# Install LLVM toolchain if configured
if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
    LLVM_PACKAGES=(
        "llvm"
        "clang"
        "clangd"
        "lld"
        "lldb"
    )
    
    for package in "${LLVM_PACKAGES[@]}"; do
        install_package "$package"
    done
fi

# Install version control tools
VCS_TOOLS=(
    "git-lfs"
    "mercurial"
    "subversion"
)

for tool in "${VCS_TOOLS[@]}"; do
    install_package "$tool"
done

# Configure git with safe directory defaults
git config --global --add safe.directory "*"

# Install ccache for faster rebuilds
install_package "ccache"
echo 'export PATH="/usr/lib/ccache:$PATH"' >> ~/.bashrc

# Install development documentation
if [ "$(get_config_value INSTALL_RECOMMENDED_PACKAGES true)" = "true" ]; then
    install_package "manpages-dev"
    install_package "manpages-posix-dev"
    install_package "cpp-doc"
    install_package "gcc-doc"
fi

# Setup core development environment
setup_dev_env() {
    # Create common development directories
    local dev_dirs=(
        "$HOME/dev"
        "$HOME/dev/projects"
        "$HOME/dev/tools"
        "$HOME/dev/scripts"
        "$HOME/dev/docs"
    )
    
    for dir in "${dev_dirs[@]}"; do
        ensure_dir "$dir"
    done
    
    # Add development environment variables
    cat >> "$HOME/.bashrc" << 'EOF'

# Development environment settings
export PATH="$HOME/dev/scripts:$PATH"
export EDITOR="$(get_config_value DEFAULT_EDITOR vim)"

# Build optimization settings
export MAKEFLAGS="-j$(nproc)"
export CFLAGS="-O2 -march=native"
export CXXFLAGS="$CFLAGS"

# ccache configuration
export CCACHE_DIR="$HOME/.ccache"
export CCACHE_SIZE="10G"
EOF
}

# Setup development environment
setup_dev_env

# Install build system tools if configured
if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
    BUILD_TOOLS=(
        "meson"
        "bazel"
        "scons"
        "bear"  # For generating compilation database
    )
    
    for tool in "${BUILD_TOOLS[@]}"; do
        install_package "$tool"
    done
fi

log_info "Core Development Tools installation completed!"