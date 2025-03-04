# VS Code

Visual Studio Code setup and configuration in PDev.

## Installation

PDev installs VS Code with a curated set of extensions and configurations optimized for development.

### Default Installation

```bash
./dev-setup.sh --components editors
```

This installs:
- VS Code from official Microsoft repository
- Git integration
- Language support extensions
- Recommended productivity extensions
- PDev-specific settings and keybindings

### Included Extensions

#### Languages & Frameworks
- Python (`ms-python.python`)
- ESLint (`dbaeumer.vscode-eslint`)
- Java Extension Pack (`vscjava.vscode-java-pack`)
- Go (`golang.go`)
- Rust Analyzer (`rust-lang.rust-analyzer`)
- Docker (`ms-azuretools.vscode-docker`)

#### Productivity
- GitLens (`eamodio.gitlens`)
- Git Graph (`mhutchie.git-graph`)
- Live Share (`ms-vsliveshare.vsliveshare`)
- Remote Development (`ms-vscode-remote.vscode-remote-extensionpack`)
- Code Spell Checker (`streetsidesoftware.code-spell-checker`)

#### Themes & UI
- Material Icon Theme (`PKief.material-icon-theme`)
- Dracula Theme (`dracula-theme.theme-dracula`)

## Configuration

### Default Settings

PDev configures VS Code with optimized settings:

```json
{
    "editor.formatOnSave": true,
    "editor.renderWhitespace": "boundary",
    "editor.rulers": [80, 100],
    "editor.minimap.enabled": false,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "terminal.integrated.defaultProfile.linux": "bash",
    "git.enableSmartCommit": true,
    "workbench.startupEditor": "none",
    "telemetry.telemetryLevel": "off"
}
```

### Custom Configuration

1. User Settings:
   ```bash
   # Edit user settings
   code ~/.pdev/editors/vscode/settings.json
   ```

2. Workspace Settings:
   ```bash
   # Create workspace settings
   mkdir -p .vscode
   code .vscode/settings.json
   ```

3. Keybindings:
   ```bash
   # Edit keybindings
   code ~/.pdev/editors/vscode/keybindings.json
   ```

## Language-Specific Setup

### Python
- Automatic virtualenv detection
- Code formatting with Black
- Linting with pylint/flake8
- Type checking with mypy
- Testing with pytest

### JavaScript/TypeScript
- ESLint integration
- Prettier formatting
- npm/yarn integration
- Debug configurations

### Java
- Project import wizard
- Maven/Gradle support
- Debugging support
- Test runner integration

### Go
- Go modules support
- Code navigation
- Debugging
- Test coverage

## Integration Features

### Git Integration
- Source control panel
- Inline blame annotations
- Branch visualization
- Merge conflict resolution

### Docker Integration
- Dockerfile syntax
- Container management
- Compose support
- Registry integration

### Remote Development
- SSH connections
- Containers
- WSL (Windows)
- GitHub Codespaces

## Productivity Features

### IntelliSense
- Smart completions
- Parameter info
- Quick info
- Member lists

### Debugging
- Multiple debug configurations
- Breakpoint management
- Variable inspection
- Call stack navigation

### Task Running
- Build tasks
- Test tasks
- Custom tasks
- Task dependencies

## Best Practices

### Workspace Organization
- Use workspace folders
- Implement consistent file structure
- Utilize workspace settings
- Configure appropriate excludes

### Performance Optimization
- Disable unnecessary extensions
- Use workspace trust
- Configure appropriate file watching
- Optimize search excludes

### Team Collaboration
- Share consistent settings
- Use EditorConfig
- Implement formatting rules
- Configure extension recommendations

## Troubleshooting

### Common Issues

1. Extension Loading
```bash
# Clear extension cache
rm -rf ~/.vscode/extensions/*
```

2. Performance Issues
```bash
# Check extension performance
code --status
```

3. Configuration Reset
```bash
# Reset to PDev defaults
cp /opt/pdev/editors/vscode/defaults/* ~/.pdev/editors/vscode/
```

### Validation

Run PDev's VS Code validation:
```bash
./run-tests.sh --component editors --tool vscode
```

## Updates

### Extension Updates
```bash
# Update all extensions
code --install-extension <extension-id>  # For each extension
```

### VS Code Updates
```bash
# Update VS Code
./dev-setup.sh --update editors
```

## Additional Resources

- [VS Code Documentation](https://code.visualstudio.com/docs)
- [Extension Marketplace](https://marketplace.visualstudio.com/vscode)
- [PDev VS Code Tips](../workflows/vscode-tips.md)
- [Remote Development](../integration/vscode-remote.md)