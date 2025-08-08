{ pkgs }:

pkgs.writeShellApplication {
  name = "git-credentials";
  runtimeInputs = with pkgs; [ coreutils ];
  text = ''
    set -euo pipefail

    # Function to print info messages
    info() { printf "\033[36mℹ %s\033[0m\n" "$*"; }
    
    # Function to print success messages
    success() { printf "\033[32m✔ %s\033[0m\n" "$*"; }
    
    # Function to print warning messages
    warn() { printf "\033[33m⚠ %s\033[0m\n" "$*"; }
    
    # Function to print error messages
    error() { printf "\033[31m✖ %s\033[0m\n" "$*" >&2; }

    # Check if 1Password CLI is available
    if ! command -v op >/dev/null 2>&1; then
      warn "1Password CLI not available"
      info "Please install 1Password CLI or manually create ~/.gitconfig.local with your git user settings"
      info "Example content:"
      info "[user]"
      info "    name = Your Name"
      info "    email = your.email@example.com"
      exit 0
    fi

    # Check if 1Password is authenticated
    if ! op vault list >/dev/null 2>&1; then
      warn "1Password CLI not authenticated"
      info "Please authenticate with 1Password CLI or manually create ~/.gitconfig.local with your git user settings"
      exit 0
    fi

    # Fetch git credentials from 1Password
    git_name=""
    git_email=""
    
    if git_name=$(op read "op://Personal/Git Config/name" 2>/dev/null); then
      info "Successfully fetched git name from 1Password"
    else
      warn "Git name not found in 1Password"
    fi
    
    if git_email=$(op read "op://Personal/Git Config/email" 2>/dev/null); then
      info "Successfully fetched git email from 1Password"
    else
      warn "Git email not found in 1Password"
    fi

    # Check if we have both name and email
    if [ -n "$git_name" ] && [ -n "$git_email" ]; then
      # Create .gitconfig.local file
      cat > "$HOME/.gitconfig.local" <<EOF
[user]
    name = $git_name
    email = $git_email
EOF
      success "Git credentials configured from 1Password"
      info "Name: $git_name"
      info "Email: $git_email"
    else
      warn "Incomplete git credentials in 1Password"
      info "Please ensure 'Git Config' item exists in 1Password with 'name' and 'email' fields"
      info "Or manually create ~/.gitconfig.local with your git user settings"
    fi
  '';
}