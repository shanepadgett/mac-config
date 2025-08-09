# macOS Home Config

A comprehensive macOS setup automation repository built with Nix that provides a complete development environment configuration.

## Quick Start

Bootstrap your Mac with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/shanepadgett/mac-config/main/install.sh | zsh
```

## Git Setup

After installation, you'll need to configure your Git credentials:

1. Launch and log into 1Password
2. Ensure 1Password CLI is installed and authenticated:
   ```bash
   op signin
   ```
3. Run the git-credentials command to automatically configure your Git user settings:
   ```bash
   git-credentials
   ```

This will fetch your Git name and email from 1Password (stored in a "Git Config" item with "name" and "email" fields) and create a `~/.gitconfig.local` file.

If you don't use 1Password, you can manually create `~/.gitconfig.local` with your details:
```ini
[user]
    name = Your Name
    email = your.email@example.com
```

## Utilities

This repository includes several custom utilities:

- `git-init` - Create and initialize new GitHub repositories with proper templates
- `git-credentials` - Configure Git credentials from 1Password
- `gcp` - Git add, commit, and push in one command
- `docker-cleanup` - Clean up Docker containers, images, volumes, and networks
- `delete-repo` - Delete a GitHub repository
