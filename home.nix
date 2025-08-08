{ pkgs, config, lib, ... }:
let
  macConfig = builtins.fetchGit {
    url = "https://github.com/shanepadgett/mac-config.git";
  };
in
{
  home.username      = "shanepadgett";
  home.homeDirectory = "/Users/shanepadgett";

  programs.home-manager.enable = true;

  # Zsh (no Oh My Zsh)
  programs.zsh.enable = true;
  programs.direnv.enable = true;
  programs.zsh.shellInit = ''
    # source user's zsh dotfile if present
    if [ -f "${macConfig}/dotfiles/zsh/.zshrc" ]; then
      source "${macConfig}/dotfiles/zsh/.zshrc"
    fi

    # ensure direnv hook is loaded for zsh
    eval "$(direnv hook zsh)"
  '';

  # Tool configs
  home.file.".config/ghostty/config".source =
    "${macConfig}/tools/ghostty/config";
  home.file.".config/direnv/direnv.toml".source =
    "${macConfig}/tools/direnv/direnv.toml";
  home.file.".config/claude/settings.json".source =
    "${macConfig}/tools/claude/settings.json";
  home.file.".config/claude/mcp.json".source =
    "${macConfig}/tools/claude/mcp.json";
  home.file.".config/zoxide/config.toml".source =
    "${macConfig}/tools/zoxide/config.toml";
  home.file.".config/zed/settings.json".source =
    "${macConfig}/tools/zed/settings.json";
  home.file.".gitconfig".source =
    "${macConfig}/tools/gitconfig";

  # Shell configs
  
}
