{ pkgs }:

pkgs.writeShellApplication {
  name = "delete-repo";
  runtimeInputs = with pkgs; [
    git
    gh
    coreutils    # realpath
    gnugrep
  ];
  text = ''
    set -euo pipefail

    info()    { printf "\033[36mℹ %s\033[0m\n" "''$*"; }
    warn()    { printf "\033[33m⚠ %s\033[0m\n" "''$*"; }
    error()   { printf "\033[31m✖ %s\033[0m\n" "''$*" >&2; }
    success() { printf "\033[32m✔ %s\033[0m\n" "''$*"; }
    header()  { printf "\n\033[1m== %s ==\033[0m\n" "''$*"; }

    usage() {
      cat >&2 <<'USAGE'
    Usage: delete-repo [REPOSITORY_NAME|.] [OPTIONS]

    Delete a repository both on GitHub and locally

    Arguments:
      REPOSITORY_NAME    Name of the repository to delete
      .                  Delete the current repository (if in a git repo)
      (none)             Auto-detect current repo or prompt for name

    Options:
      -f, --force        Skip confirmation prompts
      -l, --local-only   Delete only the local repository
      -r, --remote-only  Delete only the GitHub repository
      -h, --help         Show this help message
    USAGE
    }

    check_github_cli() {
      if ! command -v gh >/dev/null 2>&1; then
        error "GitHub CLI (gh) is required"
        return 1
      fi
    }

    check_github_auth() {
      check_github_cli || return 1
      if ! gh auth status >/dev/null 2>&1; then
        error "GitHub CLI is not authenticated"
        info  "Run: gh auth login"
        return 1
      fi
    }

    get_github_user() {
      gh api user --jq '.login' 2>/dev/null || true
    }

    get_repo_info() {
      local repo_name="''$1"
      local user
      user="$(get_github_user)"
      [ -z "''$user" ] && return 1
      local full="''$user/''$repo_name"
      if gh repo view "''$full" >/dev/null 2>&1; then
        printf "%s" "''$full"
        return 0
      fi
      return 1
    }

    delete_github_repo() {
      local full="''$1"
      local force="''$2"

      info "Deleting GitHub repository: ''$full"

      if [ "''$force" != "true" ]; then
        echo
        warn "This will permanently delete the GitHub repository: ''$full"
        warn "This action cannot be undone!"
        printf "Are you sure you want to delete this GitHub repository? [y/N]: "
        read -r confirm || true
        case "''${confirm,,}" in
          y|yes) ;;
          *) info "GitHub repository deletion cancelled"; return 1 ;;
        esac
      fi

      # Best-effort scope refresh (not strictly required anymore)
      if ! gh auth status --show-token 2>/dev/null | grep -q "delete_repo" ; then
        info "Requesting delete_repo scope for GitHub CLI..."
        if ! gh auth refresh -h github.com -s delete_repo; then
          error "Failed to refresh GitHub authentication with delete_repo scope"
          info  "Please run: gh auth refresh -h github.com -s delete_repo"
          return 1
        fi
        success "GitHub authentication refreshed with delete_repo scope"
      fi

      if gh repo delete "''$full" --yes; then
        success "GitHub repository deleted successfully"
        return 0
      else
        error "Failed to delete GitHub repository"
        return 1
      fi
    }

    delete_local_repo() {
      local path="''$1"
      local force="''$2"

      info "Deleting local repository: ''$path"

      if [ "''$force" != "true" ]; then
        echo
        warn "This will permanently delete the local directory: ''$path"
        warn "All local changes will be lost!"
        printf "Are you sure you want to delete this local repository? [y/N]: "
        read -r confirm || true
        case "''${confirm,,}" in
          y|yes) ;;
          *) info "Local repository deletion cancelled"; return 1 ;;
        esac
      fi

      local abs
      abs="$(realpath "''$path" 2>/dev/null || echo "''$path")"

      case "''$abs" in
        "$HOME" | "/" | "$HOME/.dotfiles" | "$HOME/.")
          error "Refusing to delete system directory: ''$abs"
          return 1
          ;;
      esac

      if rm -rf -- "''$path"; then
        success "Local repository deleted successfully"
        return 0
      else
        error "Failed to delete local repository"
        return 1
      fi
    }

    get_current_repo_name() {
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
      fi
      local root
      root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
      [ -z "''$root" ] && return 1
      basename "''$root"
    }

    prompt_for_repo_name() {
      local name
      while :; do
        echo
        printf "Repository name to delete: "
        read -r name || true
        if [ -n "''$name" ]; then
          case "''$name" in
            *[!a-zA-Z0-9._-]*)
              error "Repository name can only contain alphanumeric characters, dots, dashes, and underscores"
              ;;
            *)
              printf "%s" "''$name"
              return 0
              ;;
          esac
        else
          error "Repository name is required"
        fi
      done
    }

    # defaults
    repo_name=""
    delete_local=true
    delete_remote=true
    force_delete=false

    # parse args
    while [ "$#" -gt 0 ]; do
      case "''$1" in
        -h|--help) usage; exit 0 ;;
        -f|--force) force_delete=true; shift ;;
        -l|--local-only) delete_local=true; delete_remote=false; shift ;;
        -r|--remote-only) delete_local=false; delete_remote=true; shift ;;
        -*)
          error "Unknown option: ''$1"
          usage
          exit 1
          ;;
        *)
          if [ -z "''$repo_name" ]; then
            repo_name="''$1"; shift
          else
            error "Multiple repository names provided: ''$repo_name, ''$1"
            usage
            exit 1
          fi
          ;;
      esac
    done

    # resolve repo name
    if [ -z "''$repo_name" ] || [ "''$repo_name" = "." ]; then
      if rn="$(get_current_repo_name)"; then
        repo_name="''$rn"
        info "Using current repository: ''$repo_name"
      else
        if [ "''$repo_name" = "." ]; then
          error "Current directory is not a git repository"
          info  "Use 'delete-repo <name>' to specify a repository name"
          exit 1
        else
          repo_name="$(prompt_for_repo_name)"
        fi
      fi
    fi

    header "Repository Deletion Tool"

    # compute context
    local_repo_path="./''$repo_name"
    local_exists=false
    remote_exists=false
    deletion_success=true
    need_to_move_up=false
    repo_parent=""

    if git rev-parse --git-dir >/dev/null 2>&1; then
      repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
      if [ -n "''$repo_root" ]; then
        actual_repo_name="$(basename "''$repo_root")"
        if [ "''$actual_repo_name" = "''$repo_name" ]; then
          local_repo_path="."
          need_to_move_up=true
          repo_parent="$(dirname "''$repo_root")"
          info "Currently inside the repository (detected repo: ''$actual_repo_name)"
        else
          warn "Inside git repository '''$actual_repo_name' but looking for '''$repo_name'"
        fi
      fi
    fi

    # remote existence
    if [ "''$delete_remote" = "true" ]; then
      if check_github_auth; then
        if repo_full_name="$(get_repo_info "''$repo_name")"; then
          remote_exists=true
          info "Found GitHub repository: ''$repo_full_name"
        else
          warn "GitHub repository '\"''$repo_name\"' not found or not accessible"
        fi
      else
        error "Cannot delete remote repository without GitHub authentication"
      fi
    fi

    # local existence
    if [ "''$delete_local" = "true" ]; then
      if [ "''$local_repo_path" = "." ]; then
        local_exists=true
        info "Local repository confirmed (currently inside it)"
      elif [ -d "''$local_repo_path/.git" ]; then
        local_exists=true
        info "Found local repository: ''$local_repo_path"
      else
        warn "Local repository '\"''$local_repo_path\"' not found"
      fi
    fi

    if [ "''$local_exists" = false ] && [ "''$remote_exists" = false ]; then
      error "No repositories found to delete"
      exit 1
    fi

    echo
    header "Repository Deletion Summary"
    info "Repository: ''$repo_name"
    if [ "''$remote_exists" = true ]; then info "GitHub: ''${repo_full_name} (will be deleted)"; fi
    if [ "''$local_exists" = true ]; then info "Local: ''${local_repo_path} (will be deleted)"; fi

    # delete remote first
    if [ "''$delete_remote" = "true" ] && [ "''$remote_exists" = true ]; then
      if ! delete_github_repo "''$repo_full_name" "''$force_delete"; then
        deletion_success=false
      fi
    fi

    # delete local
    if [ "''$delete_local" = "true" ] && [ "''$local_exists" = true ]; then
      info "Starting local repository deletion process..."
      if [ "''$need_to_move_up" = true ]; then
        target_dir="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "''$repo_name")")"
        info "Moving to parent directory before deletion: ''$repo_parent"
        if cd "''$repo_parent"; then
          info "Successfully moved to: ''$(pwd)"
          info "Will delete repository directory: ''$target_dir"
          if ! delete_local_repo "''$target_dir" "''$force_delete"; then
            error "Local repository deletion failed"
            deletion_success=false
          fi
        else
          error "Failed to change to parent directory: ''$repo_parent"
          deletion_success=false
        fi
      else
        if ! delete_local_repo "''$local_repo_path" "''$force_delete"; then
          error "Local repository deletion failed"
          deletion_success=false
        fi
      fi
    fi

    echo
    if [ "''$deletion_success" = true ]; then
      success "Repository deletion completed successfully"
      if [ "''$need_to_move_up" = true ]; then
        info "Current directory: ''$(pwd)"
      fi
      exit 0
    else
      error "Some deletions failed. Check the output above for details."
      exit 1
    fi
  '';
}