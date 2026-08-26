{ inputs, pkgs, ... }:
{
  imports = [
    ./nginx.nix
    ./zsh.nix
    ./bind.nix
    ./smartdns.nix
  ];

  programs = {
    nix-index.enable = true;
    mtr.enable = true;
    nix-index-database.comma.enable = true;

    appimage = {
      enable = true;
      binfmt = true;
    };

    nexttrace.enable = true;

    git = {
      enable = true;
      package = pkgs.gitFull;
      config = {
        core.autocrlf = "input";
        gpg.format = "openpgp";
        sendemail = {
          smtpServer = "localhost";
          smtpServerPort = 25;
        };
        pull.ff = "only";
        credential = {
          helper = "libsecret";
          "https://github.com".helper = [
            ""
            "${pkgs.gh}/bin/gh auth git-credential"
          ];
          "https://gist.github.com".helper = [
            ""
            "${pkgs.gh}/bin/gh auth git-credential"
          ];
        };
      };
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    nixvim = {
      enable = true;
    }
    // (import ./neovim.nix { inherit inputs; });

    less = {
      enable = true;
      envVariables = {
        LESS = "RFX";
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = true;

      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
        PermitEmptyPasswords = "yes";

        KexAlgorithms = [
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group-exchange-sha256"
          "diffie-hellman-group1-sha1"
        ];

        PubkeyAcceptedKeyTypes = "ssh-ed25519,ssh-rsa,ecdsa-sha2-nistp256";
      };
    };

    iperf3 = {
      enable = true;
      openFirewall = true;
    };

    nginx.enable = true;
  };

  environment.systemPackages = with pkgs; [
    nano # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    hyfetch
    gh
    tldr
    nnn
    bottom
    gdu
    htop
    bat
    btop
    zellij
    lazygit
    nix-output-monitor
    gnumake
    file
    man-pages
    man-pages-posix
    jq
    fastfetch
    doggo
    (import ./nixfmt.nix { inherit pkgs; })
    whois
    screen
    nix-tree
  ];
}
