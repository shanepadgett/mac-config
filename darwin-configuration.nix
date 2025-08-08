
{ pkgs, config, ... }:
{
  # CLI tools (from Brewfile)
  environment.systemPackages = with pkgs; [
    python311
    uv
    bat
    direnv
    eza
    fzf
    gh
    htop
    jq
    ripgrep
    zoxide
  ];

  # Homebrew casks (GUI & dev tools)
  programs.homebrew = {
    enable = true;
    casks = [
      "1password"
      "1password-cli"
      "brave-browser"
      "bruno"
      "discord"
      "ghostty"
      "logi-options-plus"
      "orbstack"
      "raycast"
      "rectangle"
      "visual-studio-code"
      "voiceink"
      "warp"
      "zed"
    ];
  };

  # Fonts (from Brewfile)
  fonts.fonts = with pkgs; [
    jetbrains-mono
    fira-code
    sf-mono-nerd
  ];
}
