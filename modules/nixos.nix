{ modulesPath, pkgs, ... }:
{
  imports = [ (modulesPath + "/virtualisation/proxmox-lxc.nix") ];

  system.stateVersion = "24.11";

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
  };

  nix.settings.sandbox = false;

  # Disable documentation to avoid man-cache build issues in container
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;

  networking.hostName = "nixos";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    bat
    fd
    fzf
    gh
    git
    jq
    neovim
    ripgrep
    zoxide
    direnv
    mise
    age
    uv
    jujutsu
    hyperfine
    wget
    tmux
    atuin

    # Development tools
    gnumake
    openssh
    curl
    htop
  ];

  services.openssh.enable = true;
  services.tailscale.enable = true;

  # User configuration
  users.users.shardul = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };

  # Enable fish shell
  programs.fish.enable = true;

  # Post-activation script to set up dotfiles
  system.activationScripts.dotfiles = {
    text = ''
      DOTFILES_DIR="/home/shardul/Documents/dotfiles"
      if [ -d "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/Makefile.dotfiles" ]; then
        echo "Setting up dotfile symlinks..."
        cd "$DOTFILES_DIR" && sudo -u shardul make -f Makefile.dotfiles install
      fi
    '';
    deps = [];
  };
}