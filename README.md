# MarckV Setup Manager

A comprehensive server configuration management tool for Docker aliases and Bash configurations.

## 🚀 Quick Installation (Recommended)

Install the **MarckV Setup Manager** with a single command:

```bash
wget -q -O - https://raw.githubusercontent.com/villcabo/bash-setup/main/installer/marckv-setup-installer.sh | bash
```

## 📋 Usage

Once installed, you can use the manager to install and manage both Docker aliases and Bash configurations:

### Basic Commands

```bash
# Check installation status
marckv-setup status

# Install Docker aliases
marckv-setup install docker

# Install Bash configuration (basic)
marckv-setup install bash --type basic

# Install Bash configuration (full-featured)
marckv-setup install bash --type full

# Install Bash configuration for GitHub Codespaces
marckv-setup install bash --type codespace

# Install full Codespace configuration
marckv-setup install bash --type codespace_full

# Update all installed configurations
marckv-setup update

# Remove all configurations
marckv-setup uninstall

# Show help
marckv-setup help
```

### Bash Configuration Types

| Type | Description |
|------|-------------|
| `basic` | Basic bash configuration with essential features |
| `full` | Full-featured bash configuration with all enhancements |
| `codespace` | GitHub Codespace optimized configuration |
| `codespace_full` | Complete GitHub Codespace configuration |

## ✅ Installation Validation

Verify everything is working correctly:

```bash
# 1. Check if command is available
which marckv-setup

# 2. View version
marckv-setup version

# 3. Check configuration status
marckv-setup status

# 4. Test Docker aliases (after installing)
docker ps --help | grep "color"

# 5. Verify Bash configuration (after installing)
echo $PS1  # Should show a colorized prompt
```

## 🔧 Practical Examples

### Complete Server Setup
```bash
# 1. Install the manager
wget -q -O - https://raw.githubusercontent.com/villcabo/bash-setup/main/installer/marckv-setup-installer.sh | bash

# 2. Install full configuration
marckv-setup install bash --type full
marckv-setup install docker

# 3. Verify installation
marckv-setup status
source ~/.bashrc
```

### Docker Aliases Only
```bash
wget -q -O - https://raw.githubusercontent.com/villcabo/bash-setup/main/installer/marckv-setup-installer.sh | bash
marckv-setup install docker
source ~/.bashrc
```

### GitHub Codespace Setup
```bash
# Install optimized configuration for Codespaces
marckv-setup install bash --type codespace_full
markv-setup install docker
source ~/.bashrc
```

## 🛠️ Troubleshooting

### Command Not Found
**Problem**: `markv-setup: command not found`

**Solution**:
```bash
# Check PATH
echo $PATH | grep -o ~/.local/bin

# If not found, add to ~/.bashrc:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Docker Aliases Not Working
**Problem**: Docker aliases not functioning

**Solution**:
```bash
# Check installation status
markv-setup status

# Reload configuration
source ~/.bash_aliases
source ~/.bashrc
```

### Configuration Reload
After any installation, reload your shell configuration:

```bash
# For Bash
source ~/.bashrc

# For Zsh  
source ~/.zshrc

# Or simply restart your terminal
```

---

# 📁 Manual Installations (Alternative Methods)

## Bash Configuration

### Direct Manual Installation

> **Recommendation**: Use `markv-setup install bash --type <type>` instead of these manual commands.

**Basic Configuration**

```bash
cp ~/.bashrc ~/.bashrc.backup && wget -q -O ~/.bashrc https://raw.githubusercontent.com/villcabo/bash-setup/main/bash_configuration/bash_basic.sh && source ~/.bashrc
```

**Full Configuration**

```bash
cp ~/.bashrc ~/.bashrc.backup && wget -q -O ~/.bashrc https://raw.githubusercontent.com/villcabo/bash-setup/main/bash_configuration/bash_full.sh && source ~/.bashrc
```

**Codespace Full Configuration**

```bash
cp ~/.bashrc ~/.bashrc.backup && wget -q -O ~/.bashrc https://raw.githubusercontent.com/villcabo/bash-setup/main/bash_configuration/bash_codespace_full.sh && source ~/.bashrc
```

## Docker Color Output Install (Manual)

> **Recommendation**: Use `markv-setup install docker` instead of these manual commands.

This section provides instructions for manual Docker Color Output installation.

### Manual Docker Color Installation

To install Docker Color Output manually, run the following command (requires `root` privileges):

**For Docker versions 28 and above:**

```bash
wget -q -O - https://raw.githubusercontent.com/villcabo/docker-color-output/main/installer/docker-color_installers.sh | bash
```

**For Docker versions below 28:**

```bash
wget -q -O - https://raw.githubusercontent.com/villcabo/docker-color-output/main/installer/docker-color_installers.sh | bash -s -- -v 2.5.1
```

### Manual Alias Configuration

> **Recommendation**: Use `markv-setup install docker` instead of these manual commands.

To manually install alias configurations:

```bash
wget -q -O - https://raw.githubusercontent.com/villcabo/bash-setup/main/installer/markv-setup-installer.sh | bash
```

**Direct manager installation (alternative):**

```bash
wget https://raw.githubusercontent.com/villcabo/bash-setup/main/installer/markv-setup.sh -O ~/.local/bin/markv-setup
chmod +x ~/.local/bin/markv-setup
```

---

# 🔧 TMUX Configuration

## Installation

Install **TMUX** configuration:

```bash
wget -q https://raw.githubusercontent.com/villcabo/bash-setup/main/tmux_configuration/tmux.conf -O ~/.tmux.conf
```

### Tmux Plugin Manager (TPM)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

**All in one command:**

```bash
wget -q https://raw.githubusercontent.com/villcabo/bash-setup/main/tmux_configuration/tmux.conf -O ~/.tmux.conf && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

To reload the configuration, start **tmux** and press **Ctrl + A Shift + I**

**If tmux is already running, you can use this command to reload the configuration:**
```bash
tmux source ~/.tmux.conf
```

### Theme Customization

If you want to customize the theme, visit these links:
- [Tokyo Night Tmux (DEFAULT)](https://github.com/janoamaral/tokyo-night-tmux?tab=readme-ov-file)
- [Tokyo Night Tmux Theme](https://github.com/fabioluciano/tmux-tokyo-night?tab=readme-ov-file)

---

# 🎨 Banner Configuration

You can use this site to generate text:
- [Doom Font](https://patorjk.com/software/taag/#p=display&f=Doom&t=YOUR%20SERVER%0ANAME)
- [Big Font](https://patorjk.com/software/taag/#p=display&f=Big&t=YOUR%20SERVER%0ANAME)

Modify the **motd** file:

```bash
vim /etc/motd
```

---

# 📊 Monitoring Tools

## Node Exporter

Tools for server monitoring:

```bash
wget -q -O - https://raw.githubusercontent.com/villcabo/docker-color-output/main/exporter-tools/node-exporter-installers.sh | bash
```

**For a specific version (example 1.8.2):**

```bash
wget -q -O - https://raw.githubusercontent.com/villcabo/docker-color-output/main/exporter-tools/node-exporter-installers.sh | bash -s -- -v 1.8.2 --bin-only
```

---

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

If you encounter any issues or have questions, please open an issue on GitHub.

## 🔗 Related Projects

- [Docker Color Output](https://github.com/villcabo/docker-color-output)
- [Tokyo Night Tmux](https://github.com/janoamaral/tokyo-night-tmux)

---

## 👨‍💻 Author

<div align="center">
  <img src="https://github.com/villcabo.png" width="100" height="100" style="border-radius: 50%;" alt="villcabo">
  <br/>
  <strong>Bismarck Villca</strong>
  <br/>
  <a href="https://github.com/villcabo">
    <img src="https://img.shields.io/badge/GitHub-villcabo-blue?style=flat-square&logo=github" alt="GitHub Profile">
  </a>
  <br/>
  <a href="https://github.com/villcabo/bash-setup">
    <img src="https://img.shields.io/badge/Repository-bash--setup-green?style=flat-square&logo=github" alt="Repository">
  </a>
</div>

### 🌐 Connect with me:

[![GitHub](https://img.shields.io/badge/GitHub-villcabo-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/villcabo)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-villcabo-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/villcabo)
[![Twitter](https://img.shields.io/badge/Twitter-@villcabo-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/villcabo)

---

⭐ **If this project helped you, please consider giving it a star!** ⭐

*Built with ❤️ by villcabo*
