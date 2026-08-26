{
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://mirrors.cernet.edu.cn/nix-channels/store"
      "https://mirrors.bfsu.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"

      "https://nix-community.cachix.org"
      "https://cryolitia.cachix.org"
      "http://cache.cryolitia.dn42"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cryolitia.cachix.org-1:/RUeJIs3lEUX4X/oOco/eIcysKZEMxZNjqiMgXVItQ8="
      "kp920.cryolitia.dn42:M68UcYMNX/2yWXFwDb21jAregdcIsF3uIrSmXldX70k="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    nixvim = {
      url = "github:nix-community/nixvim";
      # If you are not running an unstable channel of nixpkgs, select the corresponding branch of nixvim.
      # url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dnsmasq-china-list = {
      url = "github:felixonmars/dnsmasq-china-list";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, self, ... }@inputs:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      eachSystem = inputs.nixpkgs.lib.genAttrs systems;
      lib = nixpkgs.lib;
    in
    builtins.trace "「我书写，则为我命令。我陈述，则为我规定。」" {
      # nixosConfigurations.[name].config.system.build.toplevel
      nixosConfigurations = {
        hemimorph-root-server = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            inputs.nixvim.nixosModules.nixvim
            inputs.nix-index-database.nixosModules.nix-index

            ./hemimorph-root-server.nix
          ];
        };
      };

      packages.x86_64-linux = {
        hemimorph-root-server-lxc =
          self.nixosConfigurations.hemimorph-root-server.config.system.build.image;
      };

      formatter = eachSystem (
        system:
        (import ./software/nixfmt.nix {
          pkgs = import inputs.nixpkgs {
            inherit system;
            specialArgs = { inherit inputs; };
          };
        })
      );

      hydraJobs = self.packages;
    };
}
