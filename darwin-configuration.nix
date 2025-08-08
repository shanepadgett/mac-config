
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

  # System defaults
  system.defaults = {
    # Dock Configuration
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.5;
      tilesize = 48;
      orientation = "bottom";
      show-recents = false;
      minimize-to-application = true;
      persistent-apps = [
        "/Applications/Brave Browser.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/Zed.app"
        "/Applications/Warp.app"
        "/Applications/Bruno.app"
        "/Applications/Obsidian.app"
        "/Applications/1Password.app"
        "/Applications/Discord.app"
        "/Applications/OrbStack.app"
      ];
    };

    # Trackpad Configuration
    trackpad = {
      Clicking = true;
    };

    # Apple Multitouch Trackpad Configuration
    "com.apple.AppleMultitouchTrackpad" = {
      TrackpadThreeFingerDrag = true;
    };

    # Apple Bluetooth Multitouch Trackpad Configuration
    "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
      TrackpadThreeFingerDrag = true;
    };

    # Finder Configuration
    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
    };

    # Desktop Configuration
    "com.apple.WindowManager" = {
      EnableStandardClickToShowDesktop = false;
    };

    # Global Domain settings
    NSGlobalDomain = {
      AppleEnableSwipeNavigateWithScrolls = true;
    };
  };

  # Enable three-finger drag for trackpad
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
}
