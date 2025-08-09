{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.

  home.username      = "shanepadgett";
  home.homeDirectory = "/Users/shanepadgett";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  programs.git = {
    enable = true;
    includes = [
      { path = "${config.home.homeDirectory}/.config/mac-config/tools/gitconfig"; }
      { path = "${config.home.homeDirectory}/.gitconfig.local"; }
    ];
  };

  programs.zsh.enable = true;
  programs.direnv.enable = true;
  programs.zsh.shellInit = ''
    # source user's zsh dotfile if present
    if [ -f "$HOME/.zshrc" ]; then
      source "$HOME/.zshrc"
    fi

    # ensure direnv hook is loaded for zsh
    eval "$(direnv hook zsh)"
  '';

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = let
    macUtils = pkgs.callPackage ./nix/pkgs/mac-utils {
      templatesDir = ./templates;
    }; in [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    macUtils.gcp
    macUtils."delete-repo"
    macUtils."docker-cleanup"
    macUtils."git-init"
    macUtils."git-credentials"
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    # Tool configs (editable - direct symlinks to repo)
    ".config/ghostty/config".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/tools/ghostty/config";
    ".config/direnv/direnv.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/tools/direnv/direnv.toml";
    ".config/claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/tools/claude/settings.json";
    ".config/claude/mcp.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/tools/claude/mcp.json";
    ".config/zoxide/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/tools/zoxide/config.toml";
    ".config/zed/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/tools/zed/settings.json";
    ".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/tools/gitconfig";

    # Shell configs (editable - direct symlinks to repo)
    ".aliases".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/shell/aliases";
    ".bashrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/shell/bashrc";
    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/shell/zshrc";
    ".exports".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/mac-config/shell/exports";
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/davish/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}















# OLD CONFIG


# { pkgs, config, lib, ... }:
# let
#   macConfig = builtins.fetchGit {
#     url = "https://github.com/shanepadgett/mac-config.git";
#   };
# in
# {
#   home.username      = builtins.getEnv "USER";
#   home.homeDirectory = builtins.getEnv "HOME";

#   programs.home-manager.enable = true;

#   # Git configuration
#   programs.git = {
#     enable = true;
#     includes = [
#       { path = "tools/gitconfig"; }
#       { path = "~/.gitconfig.local"; }
#     ];
#   };

#   # Zsh (no Oh My Zsh)
#   programs.zsh.enable = true;
#   programs.direnv.enable = true;
#   programs.zsh.shellInit = ''
#     # source user's zsh dotfile if present
#     if [ -f "dotfiles/zsh/.zshrc" ]; then
#       source "dotfiles/zsh/.zshrc"
#     fi

#     # ensure direnv hook is loaded for zsh
#     eval "$(direnv hook zsh)"
#   '';

  # Tool configs
  # home.file.".config/ghostty/config".source =
  #   "tools/ghostty/config";
  # home.file.".config/direnv/direnv.toml".source =
  #   "tools/direnv/direnv.toml";
  # home.file.".config/claude/settings.json".source =
  #   "tools/claude/settings.json";
  # home.file.".config/claude/mcp.json".source =
  #   "tools/claude/mcp.json";
  # home.file.".config/zoxide/config.toml".source =
  #   "tools/zoxide/config.toml";
  # home.file.".config/zed/settings.json".source =
  #   "tools/zed/settings.json";
  # home.file.".gitconfig".source =
  #   "tools/gitconfig";

  # # Shell configs
  # home.file.".aliases".source =
  #   "shell/aliases";
  # home.file.".bashrc".source =
  #   "shell/bashrc";
  # home.file.".zshrc".source =
  #   "shell/zshrc";
  # home.file.".exports".source =
  #   "shell/exports";

  # # Packaged CLI tools from this repo
  # home.packages = let
  #   macUtils = pkgs.callPackage "nix/pkgs/mac-utils" {
  #     templatesDir = "templates";
  #   };
  # in [
  #   macUtils.gcp
  #   macUtils."delete-repo"
  #   macUtils."docker-cleanup"
  #   macUtils."git-init"
  #   macUtils."git-credentials"
  # ];
# }
