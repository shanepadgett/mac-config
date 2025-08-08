{ pkgs, templatesDir }:

pkgs.writeShellApplication {
  name = "git-init";
  runtimeInputs = with pkgs; [
    git
    gh
    gnused     # provides GNU sed as 'sed' on PATH for -i behavior
    coreutils  # realpath, basename, dirname
  ];
  text = ''
    set -euo pipefail

    info()    { printf "\033[36mℹ %s\033[0m\n" "''$*"; }
    warn()    { printf "\033[33m⚠ %s\033[0m\n" "''$*"; }
    error()   { printf "\033[31m✖ %s\033[0m\n" "''$*" >&2; }
    success() { printf "\033[32m✔ %s\033[0m\n" "''$*"; }
    header()  { printf "\n\033[1m== %s ==\033[0m\n" "''$*"; }

    TEMPLATES_DIR="${templatesDir}"

    # checks
    check_git_user_config() {
      local name email
      name="$(git config user.name || true)"
      email="$(git config user.email || true)"
      if [ -z "''$name" ] || [ -z "''$email" ]; then
        error "Git user configuration is not set"
        info  'Run: git config --global user.name "Your Name"'
        info  '     git config --global user.email "you@example.com"'
        return 1
      fi
      return 0
    }

    check_github_auth() {
      if ! command -v gh >/dev/null 2>&1; then
        error "GitHub CLI (gh) is required"
        return 1
      fi
      if ! gh auth status >/dev/null 2>&1; then
        warn "GitHub CLI is not authenticated"
        printf "Run 'gh auth login' now? [Y/n]: "
        read -r do_login || true
        case "''${do_login,,}" in
          ""|y|yes)
            if ! gh auth login; then
              error "GitHub authentication failed"
              return 1
            fi
            ;;
          *) error "GitHub authentication required"; return 1 ;;
        esac
      fi
      success "GitHub CLI authenticated"
      return 0
    }

    # prompts
    prompt_repo_details() {
      while :; do
        echo
        printf "Repository name: "
        read -r repo_name || true
        if [ -n "''$repo_name" ]; then
          case "''$repo_name" in
            *[!a-zA-Z0-9._-]*)
              error "Name can only contain alphanumeric, dot, dash, underscore"
              ;;
            *) break ;;
          esac
        else
          error "Repository name is required"
        fi
      done

      echo
      printf "Description (optional): "
      read -r repo_description || true

      echo
      info "Visibility:"
      echo "  1) Private [default]"
      echo "  2) Public"
      echo "  3) Internal"
      while :; do
        printf "Choose visibility [1-3] (default: 1): "
        read -r vis || true
        vis="''${vis:-1}"
        case "''$vis" in
          1) repo_visibility="private"; break ;;
          2) repo_visibility="public"; break ;;
          3) repo_visibility="internal"; break ;;
          *) error "Please choose 1, 2, or 3" ;;
        esac
      done

      echo
      info "Project location:"
      echo "  1) Create in new subdirectory ./'$repo_name' [default]"
      echo "  2) Create in current directory"
      while :; do
        printf "Choose location [1-2] (default: 1): "
        read -r loc || true
        loc="''${loc:-1}"
        case "''$loc" in
          1) project_location="subdirectory"; break ;;
          2) project_location="current"; break ;;
          *) error "Please choose 1 or 2" ;;
        esac
      done

      echo
      printf "Add .gitignore from template? [Y/n] (default: Y): "
      read -r add_gitignore || true
      add_gitignore="''${add_gitignore:-Y}"
      case "''${add_gitignore,,}" in
        n|no) add_gitignore=false ;;
        *)    add_gitignore=true ;;
      esac
    }

    # setup README and .gitignore
    scaffold_files() {
      local name="''$1"
      local desc="''$2"
      if [ ! -f README.md ]; then
        if [ -f "''$TEMPLATES_DIR/README.md" ]; then
          cp "''$TEMPLATES_DIR/README.md" README.md
          sed -i 's/PROJECT_NAME/'"''${name//\//\\/}"'/g' README.md
          sed -i 's/PROJECT_DESCRIPTION/'"''${desc//\//\\/}"'/g' README.md
          success "README.md created from template"
        else
          warn "README template not found; skipping"
        fi
      else
        warn "README.md already exists; skipping"
      fi

      if [ "''$add_gitignore" = true ] && [ ! -f .gitignore ]; then
        if [ -f "''$TEMPLATES_DIR/gitignore" ]; then
          cp "''$TEMPLATES_DIR/gitignore" .gitignore
          success ".gitignore created from template"
        else
          warn "gitignore template not found; skipping"
        fi
      fi
    }

    initial_commit_and_push() {
      local message="feat: initial project setup

- Add README.md with project structure
- Add .gitignore
- Set up basic project foundation"
      info "Creating initial commit and pushing..."
      git add --all
      if git diff --cached --quiet; then
        warn "No changes to commit"
      else
        git commit -m "''$message"
      fi

      if ! git remote get-url origin >/dev/null 2>&1; then
        local user
        user="$(gh api user --jq '.login' 2>/dev/null || true)"
        if [ -n "''$user" ]; then
          local url="git@github.com:''$user/''$repo_name.git"
          info "Adding remote origin: ''$url"
          git remote add origin "''$url"
        else
          warn "Could not determine GitHub username; remote not configured"
        fi
      fi

      if git remote get-url origin >/dev/null 2>&1; then
        # Determine branch; default to currently checked out or main if new
        current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo main)"
        git push -u origin "''$current_branch" || git push -u origin HEAD
        success "Initial commit pushed"
      else
        warn "No remote configured; skipping push"
      fi
    }

    main() {
      header "GitHub Repository Creation"
      check_git_user_config || exit 1
      check_github_auth || exit 1

      prompt_repo_details

      header "Creating Repository: ''$repo_name"
      if [ "''$project_location" = "subdirectory" ]; then
        # Create on GitHub and clone locally
        cmd="gh repo create ''$repo_name --''$repo_visibility"
        [ -n "''$repo_description" ] && cmd="''$cmd --description \"$repo_description\""
        cmd="''$cmd --clone"
        info "Running: ''$cmd"
        eval "''$cmd"
        cd "''$repo_name"

        # Ensure repo initialized
        if [ ! -d .git ]; then
          info "Initializing git repository..."
          git init
        fi

        scaffold_files "''$repo_name" "''$repo_description"
        initial_commit_and_push
      else
        # Current directory mode
        # Create GitHub repository remotely only
        cmd="gh repo create ''$repo_name --''$repo_visibility"
        [ -n "''$repo_description" ] && cmd="''$cmd --description \"$repo_description\""
        info "Running: ''$cmd"
        eval "''$cmd"

        # Initialize local repo if needed
        if [ ! -d .git ]; then
          info "Initializing git repository in current directory..."
          git init
        else
          warn "Git repository already exists here"
        fi

        scaffold_files "''$repo_name" "''$repo_description"

        # Ensure remote origin points to the new repo
        if ! git remote get-url origin >/dev/null 2>&1; then
          user="$(gh api user --jq '.login' 2>/dev/null || true)"
          if [ -n "''$user" ]; then
            url="git@github.com:''$user/''$repo_name.git"
            info "Adding remote origin: ''$url"
            git remote add origin "''$url"
          else
            warn "Could not determine GitHub username; remote not configured"
          fi
        fi

        initial_commit_and_push
      fi

      echo
      success "Repository setup complete!"
      info "Location: ''$(pwd)"
      info "GitHub: https://github.com/$(gh api user --jq '.login' 2>/dev/null)/''$repo_name"
    }

    main "''$@"
  '';
}