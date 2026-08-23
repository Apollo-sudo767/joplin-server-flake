{
  description = "Joplin Server with local PostgreSQL database and Nginx reverse proxy + SSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    joplin-server.url = "github:Apollo-sudo767/joplin-server-flake";
  };

  outputs = { self, nixpkgs, joplin-server }: {
    nixosConfigurations.joplin-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        joplin-server.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
