# PDev - Professional Development Environment Setup

A comprehensive automation toolkit for creating and managing complete development environments on Linux systems. PDev not only handles installation but also provides validation, backup/restore functionality, and continuous environment health monitoring.

## 🚀 Features

### Core Components
- **Programming Languages & SDKs**:
  - Node.js with npm/yarn
  - Python with pip/virtualenv
  - Java with Maven/Gradle
  - Go with common tools
  - Rust with Cargo
  - PHP with Composer
  - Ruby with RVM/rbenv

- **Databases**:
  - PostgreSQL with pgAdmin
  - MongoDB with Compass
  - MySQL/MariaDB with Workbench
  - Redis with RedisInsight
  - SQLite with GUI tools
  - Elasticsearch with Kibana

- **Container & Orchestration**:
  - Docker with Docker Compose
  - Kubernetes tools (kubectl, minikube, helm)
  - Podman, Buildah, and Skopeo
  - Container monitoring (ctop, lazydocker)

- **Cloud Development**:
  - AWS CLI and SDK
  - Azure CLI and tools
  - Google Cloud SDK
  - Terraform and providers
  - Serverless Framework
  - Cloud-native development tools

### Development Tools

- **Code Editors & IDEs**:
  - VS Code with extensions
  - Neovim with modern config
  - Sublime Text
  - JetBrains Toolbox
  - Language-specific IDEs

- **DevOps Tools**:
  - Git and advanced tools
  - Jenkins
  - GitLab Runner
  - Ansible
  - Prometheus & Grafana
  - ArgoCD
  - Security scanners

- **Utility Tools**:
  - Terminal multiplexer (tmux)
  - Modern CLI tools (fzf, ripgrep, bat)
  - System monitoring (htop, btop)
  - JSON processor (jq)
  - Network tools
  - Development utilities

## 🎯 Key Features

- **Automated Setup**: One-command installation of your entire development environment
- **Validation Testing**: Comprehensive test suite to verify installations
- **Backup & Restore**: Save and restore your complete environment configuration
- **Health Monitoring**: Continuous environment health checks
- **Modular Design**: Install only what you need
- **Cross-Distribution**: Supports major Linux distributions
- **Configuration Management**: Version-controlled environment settings
- **Security Best Practices**: Follows security guidelines for tool installation
- **Plugin System**: Extensible architecture for custom tools

## 🔧 Prerequisites

- Linux-based operating system:
  - Ubuntu/Debian (20.04+)
  - Fedora (34+)
  - CentOS/RHEL (8+)
  - Arch Linux
- sudo privileges
- Internet connection
- Git

## 📦 Installation

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

## 🎮 Usage

### Basic Setup

1. Run the interactive setup:
```bash
sudo ./dev-setup.sh
```

2. Choose installation categories:
- All components (complete setup)
- Core Development Tools
- Programming Languages
- Databases
- Container Tools
- Cloud Development
- Utility Tools
- Code Editors
- DevOps Tools

### Advanced Features

#### Environment Validation
```bash
sudo ./run-tests.sh
```
Runs comprehensive tests to validate your development environment.

#### Quick Health Check
```bash
./verify.sh
```
Performs a quick health check of essential services and tools.

#### Backup and Restore
```bash
# Create backup
sudo ./backup-restore.sh backup

# Restore from latest backup
sudo ./backup-restore.sh restore

# Restore from specific backup
sudo ./backup-restore.sh restore /opt/pdev/backups/pdev_backup_20230815_123456.tar.gz
```

#### Uninstallation
```bash
sudo ./uninstall.sh
```
Safely removes installed components with option to keep configurations.

## ⚙️ Configuration

### Directory Structure
- `core/`: Core development tools
- `languages/`: Programming language installations
- `databases/`: Database systems
- `containers/`: Container and orchestration tools
- `cloud/`: Cloud development tools
- `editors/`: Code editors and IDEs
- `devops/`: DevOps tools
- `utils/`: Utility tools
- `tests/`: Validation test scripts
- `docs/`: Documentation

### Configuration Files
- `/opt/pdev/config/`: Global configurations
- `~/.pdev/`: User-specific settings
- Individual tool configurations in respective directories

## 🔍 Validation Tests

PDev includes comprehensive validation tests for:
- Programming language installations
- Database configurations
- Container setup
- Cloud tool authentication
- Editor plugins and extensions
- DevOps tool integration
- Backup integrity
- Environment health

## 🛠️ Customization

### Adding Custom Tools
1. Create a new directory under the appropriate category
2. Add your `install.sh` script
3. Create corresponding validation tests
4. Update the main menu in `dev-setup.sh`

### Modifying Existing Tools
Edit the respective `install.sh` scripts in each category directory:
- `languages/install.sh`: Programming languages
- `databases/install.sh`: Database systems
- `containers/install.sh`: Container tools
- `cloud/install.sh`: Cloud development tools
- `editors/install.sh`: Code editors
- `devops/install.sh`: DevOps tools

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch:
```bash
git checkout -b feature/amazing-feature
```
3. Make your changes
4. Run validation tests:
```bash
sudo ./run-tests.sh
```
5. Commit your changes:
```bash
git commit -m 'Add amazing feature'
```
6. Push to the branch:
```bash
git push origin feature/amazing-feature
```
7. Open a Pull Request

### Development Guidelines
- Follow shell scripting best practices
- Add validation tests for new features
- Update documentation
- Maintain cross-distribution compatibility
- Consider security implications

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Open source community
- Tool maintainers
- Contributors

## 📚 Additional Resources

- [Installation Guide](docs/installation.md)
- [Configuration Guide](docs/configuration.md)
- [Tool Documentation](docs/)