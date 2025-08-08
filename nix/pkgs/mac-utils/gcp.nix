{ pkgs }:

pkgs.writeShellApplication {
  name = "gcp";
  runtimeInputs = with pkgs; [ git ];
  text = ''
    set -euo pipefail

    if [ $# -lt 1 ]; then
      echo "Error: Commit message required" >&2
      echo 'Usage: gcp "commit message"' >&2
      exit 1
    fi

    # Ensure inside a git repo
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      echo "Error: not a git repository" >&2
      exit 1
    fi

    # Check git user config
    git_name=$(git config user.name || true)
    git_email=$(git config user.email || true)
    if [ -z "''${git_name}" ] || [ -z "''${git_email}" ]; then
      echo "Error: Git user configuration is not set" >&2
      echo 'Run: git config --global user.name "Your Name"' >&2
      echo '     git config --global user.email "you@example.com"' >&2
      exit 1
    fi

    git add --all
    git commit -m "$*"
    if git rev-parse --verify --quiet HEAD >/dev/null; then
      if git remote get-url origin >/dev/null 2>&1; then
        git push
      else
        echo "Warning: no '\''origin'\'' remote; skipping push"
      fi
    fi
  '';
}