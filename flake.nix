{
  description = "Nix flake for Joplin Server with comprehensive options and toggles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      nixosModule = import ./module.nix;
    in
    {
      # Export NixOS Module for consumption in NixOS configurations
      nixosModules = {
        joplin-server = nixosModule;
        default = nixosModule;
      };
    } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        joplinServerPkg = import ./package.nix { inherit pkgs; };
      in
      {
        # Package outputs
        packages = {
          joplin-server = joplinServerPkg;
          default = joplinServerPkg;
        };

        # Application outputs for `nix run`
        apps = {
          joplin-server = flake-utils.lib.mkApp { drv = joplinServerPkg; };
          default = flake-utils.lib.mkApp { drv = joplinServerPkg; };
        };

        # Verification checks for `nix flake check`
        checks = {
          package = joplinServerPkg;
        };
      }
    ) // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Development shell for `nix develop`
        devShells.default = pkgs.mkShell {
          name = "joplin-server-dev";
          buildInputs = with pkgs; [
            nixpkgs-fmt
            statix
            git
            jq
            curl
            nix-prefetch-docker
          ];
          shellHook = ''
            echo "🚀 Joplin Server Flake Development Shell"
            echo "Commands: nixpkgs-fmt, statix, ./scripts/update.sh"
          '';
        };
      }
    ) // {
      # Overlay for nixpkgs
      overlays.default = final: prev: {
        joplin-server = import ./package.nix { pkgs = final; };
      };

      # Templates for initializing Joplin Server projects
      templates = {
        default = {
          path = ./templates/basic;
          description = "Basic Joplin Server NixOS module setup";
        };
        postgres-nginx = {
          path = ./templates/postgres-nginx;
          description = "Joplin Server with local PostgreSQL database and Nginx reverse proxy";
        };
        caddy-mailer = {
          path = ./templates/caddy-mailer;
          description = "Joplin Server with Caddy reverse proxy and SMTP Mailer enabled";
        };
      };
    };
}
