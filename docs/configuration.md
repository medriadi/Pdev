# PDev Configuration Guide

This guide explains how to configure and customize your PDev installation.

## Configuration Hierarchy

PDev uses a hierarchical configuration system:

1. **System-wide configuration**: `/opt/pdev/config/`
2. **User-specific configuration**: `~/.pdev/`
3. **Project-specific overrides**: `.pdev/` in project directories

Configuration files in more specific locations override broader ones.

## Configuration Files

### Main Configuration

The main configuration file is `config.sh`:

```bash
# Basic Settings
PDEV_HOME="/opt/pdev"
DEFAULT_SHELL="bash"
BACKUP_ENABLED=true
INSTALL_RECOMMENDED=true

# Installation Preferences
DEFAULT_CLOUD="aws"  # aws, azure, or gcloud
INSTALL_MULTIPLE_CLOUDS=true
MINIMAL_INSTALLATION=false
INSTALL_DESKTOP_TOOLS=true

# Language Versions
NODE_VERSION="lts"
PYTHON_VERSION="3.11"
GO_VERSION="1.21"
JAVA_VERSION="17"
RUBY_VERSION="3.2"
PHP_VERSION="8.2"

# Database Settings
POSTGRESQL_VERSION="15"
MONGODB_VERSION="6.0"
MYSQL_VERSION="8.0"
REDIS_VERSION="7.0"

# Editor Settings
DEFAULT_EDITOR="vscode"  # vscode, nvim, sublime, or idea
INSTALL_VSCODE_EXTENSIONS=true
SETUP_NEOVIM_CONFIG=true
INSTALL_JETBRAINS=false

# Container Settings
DOCKER_COMPOSE_VERSION="v2"
INSTALL_KUBERNETES=true
SETUP_MINIKUBE=true
USE_PODMAN=false

# Backup Settings
BACKUP_DATABASES=true
BACKUP_CONTAINERS=true
BACKUP_FREQUENCY="weekly"
BACKUP_RETENTION_DAYS=30

# Security Settings
ENFORCE_SECURITY_POLICIES=true
INSTALL_SECURITY_TOOLS=true
USE_SECURE_PROTOCOLS=true
```

### Tool-specific Configurations

1. **Editor Configurations**
   - VS Code: `~/.pdev/editors/vscode/settings.json`
   - Neovim: `~/.pdev/editors/nvim/init.vim`
   - Sublime: `~/.pdev/editors/sublime/Preferences.sublime-settings`

2. **Shell Configurations**
   - Bash: `~/.pdev/shell/bashrc`
   - Zsh: `~/.pdev/shell/zshrc`
   - Fish: `~/.pdev/shell/config.fish`

3. **Git Configuration**
   ```ini
   # ~/.pdev/git/gitconfig
   [user]
       name = Your Name
       email = your.email@example.com
   
   [core]
       editor = code --wait
       pager = delta
   
   [init]
       defaultBranch = main
   ```

## Environment Variables

PDev sets up the following environment variables:

```bash
# Core paths
export PDEV_HOME="/opt/pdev"
export PDEV_CONFIG_HOME="$HOME/.pdev"
export PDEV_BACKUP_DIR="/opt/pdev/backups"

# Development paths
export WORKSPACE="$HOME/dev/workspace"
export GOPATH="$HOME/dev/go"
export JAVA_HOME="/usr/lib/jvm/default-java"
export NODE_PATH="$HOME/.node_modules"

# Tool configurations
export DOCKER_CONFIG="$HOME/.docker"
export KUBECONFIG="$HOME/.kube/config"
export AWS_CONFIG_FILE="$HOME/.aws/config"
export AZURE_CONFIG_DIR="$HOME/.azure"

# Editor settings
export EDITOR="code"
export VISUAL="code"
```

## Customization

### Adding Custom Tools

1. Create a new installation script:

```bash
# ~/.pdev/custom/mytool/install.sh
#!/bin/bash

install_mytool() {
    # Installation logic
    echo "Installing mytool..."
}

configure_mytool() {
    # Configuration logic
    echo "Configuring mytool..."
}

validate_mytool() {
    # Validation logic
    echo "Validating mytool..."
}

# Main installation
install_mytool
configure_mytool
validate_mytool
```

2. Register the tool in PDev:

```bash
# ~/.pdev/custom/register.sh
CUSTOM_TOOLS+=("mytool")
CUSTOM_TOOL_PATHS+=("$PDEV_CONFIG_HOME/custom/mytool")
```

### Modifying Default Configurations

1. **Language Settings**
   ```bash
   # ~/.pdev/config/languages.conf
   python_packages=(
       "pytest"
       "black"
       "mypy"
       "poetry"
   )
   
   node_packages=(
       "typescript"
       "eslint"
       "prettier"
   )
   ```

2. **Database Settings**
   ```bash
   # ~/.pdev/config/databases.conf
   postgresql_settings=(
       "max_connections = 100"
       "shared_buffers = 256MB"
       "work_mem = 16MB"
   )
   ```

3. **Editor Extensions**
   ```json
   // ~/.pdev/config/vscode_extensions.json
   {
     "extensions": [
       "ms-python.python",
       "dbaeumer.vscode-eslint",
       "golang.go"
     ]
   }
   ```

## Integration

### CI/CD Integration

```yaml
# .github/workflows/pdev-validate.yml
name: PDev Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run PDev tests
        run: |
          sudo ./run-tests.sh --ci
```

### Container Integration

```dockerfile
# Dockerfile.pdev
FROM ubuntu:22.04

COPY . /opt/pdev/
WORKDIR /opt/pdev

RUN ./dev-setup.sh --minimal --non-interactive
```

## Maintenance

### Regular Updates

```bash
# Update script
./dev-setup.sh --update-all
```

### Backup Management

```bash
# Automated backup
crontab -e
# Add: 0 0 * * 0 /opt/pdev/backup-restore.sh backup

# Cleanup old backups
find /opt/pdev/backups -name "pdev_backup_*.tar.gz" -mtime +30 -delete
```

### Health Monitoring

```bash
# Add to crontab for hourly checks
0 * * * * /opt/pdev/verify.sh --quiet || notify-send "PDev: Environment issues detected"
```

## Troubleshooting

### Common Configuration Issues

1. **Path Issues**
   ```bash
   # Add to ~/.pdev/shell/path.sh
   export PATH="$PDEV_HOME/bin:$PATH"
   ```

2. **Permission Issues**
   ```bash
   # Fix permissions
   sudo chown -R $USER:$USER ~/.pdev
   sudo chmod -R 755 ~/.pdev/bin
   ```

3. **Tool Conflicts**
   ```bash
   # Use update-alternatives
   sudo update-alternatives --config python
   sudo update-alternatives --config editor
   ```

## Security

### Best Practices

1. **API Keys**: Store in `~/.pdev/secrets/` (encrypted)
2. **SSH Keys**: Use `~/.pdev/ssh/` with proper permissions
3. **Credentials**: Use environment-specific credential files

### Audit

```bash
# Security audit
./verify.sh --security-audit
```

## Version Control

Keep your configurations in version control:

```bash
# Initialize configuration repo
cd ~/.pdev
git init
git remote add origin <your-repo-url>

# Ignore sensitive files
echo "secrets/" >> .gitignore
echo "*.key" >> .gitignore

# Commit and push
git add .
git commit -m "Initial PDev configuration"
git push -u origin main
```