# PDev Installation Guide

This guide provides detailed instructions for installing PDev on different Linux distributions.

## System Requirements

### Hardware Requirements
- CPU: 2+ cores recommended
- RAM: 4GB minimum, 8GB+ recommended
- Disk Space: 20GB+ free space recommended

### Software Requirements
- Linux distribution:
  - Ubuntu 20.04+ or Debian 11+
  - Fedora 34+
  - CentOS/RHEL 8+
  - Arch Linux (latest)
- Git
- curl or wget
- sudo privileges
- Internet connection

## Pre-Installation Steps

1. Update your system:

   **Ubuntu/Debian:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

   **Fedora:**
   ```bash
   sudo dnf upgrade -y
   ```

   **CentOS/RHEL:**
   ```bash
   sudo yum update -y
   ```

   **Arch Linux:**
   ```bash
   sudo pacman -Syu
   ```

2. Install basic dependencies:

   **Ubuntu/Debian:**
   ```bash
   sudo apt install -y git curl wget
   ```

   **Fedora:**
   ```bash
   sudo dnf install -y git curl wget
   ```

   **CentOS/RHEL:**
   ```bash
   sudo yum install -y git curl wget
   ```

   **Arch Linux:**
   ```bash
   sudo pacman -S git curl wget
   ```

## Installation Methods

### Method 1: Quick Install (Recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/pdev.git
   cd pdev
   ```

2. Make scripts executable:
   ```bash
   chmod +x *.sh
   ```

3. Run the setup script:
   ```bash
   sudo ./dev-setup.sh
   ```

4. Follow the interactive prompts to select components to install.

### Method 2: Custom Installation

1. Clone and prepare as above, but instead of running dev-setup.sh directly, you can:

   a. Edit configuration first:
   ```bash
   cp config.sh.example config.sh
   nano config.sh  # or your preferred editor
   ```

   b. Run specific component installations:
   ```bash
   sudo ./dev-setup.sh --components "languages databases editors"
   ```

## Post-Installation

1. Run validation tests:
   ```bash
   sudo ./run-tests.sh
   ```

2. Verify the installation:
   ```bash
   ./verify.sh
   ```

3. Create initial backup:
   ```bash
   sudo ./backup-restore.sh backup
   ```

## Installation Options

### Component Categories

1. **Core Tools**
   - Essential build tools
   - Version control systems
   - Basic development utilities

2. **Programming Languages**
   - Node.js and npm
   - Python and pip
   - Java and build tools
   - Go
   - Rust
   - PHP
   - Ruby

3. **Databases**
   - PostgreSQL
   - MongoDB
   - MySQL/MariaDB
   - Redis
   - SQLite
   - Elasticsearch

4. **Container Tools**
   - Docker and Docker Compose
   - Kubernetes tools
   - Podman and related tools

5. **Cloud Tools**
   - AWS CLI
   - Azure CLI
   - Google Cloud SDK
   - Terraform
   - Cloud-native tools

6. **Editors**
   - VS Code
   - Neovim
   - Sublime Text
   - JetBrains Toolbox

7. **DevOps Tools**
   - Jenkins
   - GitLab Runner
   - Ansible
   - Monitoring tools

8. **Utility Tools**
   - Terminal utilities
   - Development helpers
   - System monitoring

## Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   sudo chown -R $USER:$USER ~/.pdev
   ```

2. **Package Manager Issues**
   - Clear package manager cache
   - Update package lists
   - Check system proxy settings

3. **Space Issues**
   - Clear old packages
   - Remove unused Docker images
   - Clean package manager cache

### Getting Help

1. Check the logs:
   ```bash
   cat /var/log/pdev/install.log
   ```

2. Run diagnostics:
   ```bash
   ./verify.sh --verbose
   ```

3. Generate a system report:
   ```bash
   sudo ./run-tests.sh --report
   ```

## Updating PDev

1. Update the repository:
   ```bash
   git pull origin main
   ```

2. Run update script:
   ```bash
   sudo ./dev-setup.sh --update
   ```

3. Validate the update:
   ```bash
   sudo ./run-tests.sh
   ```

## Security Considerations

- All installations use official package sources
- Configurations follow security best practices
- Regular security updates are recommended
- Sensitive data is backed up securely

## Next Steps

- Review [Configuration Guide](configuration.md)
- Set up your preferred tools
- Create development workspace
- Configure version control
- Set up cloud provider credentials