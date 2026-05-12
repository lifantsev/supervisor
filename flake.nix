{
    description = "a daemon that keeps track of what activity you are doing";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

        lg.url = "github:lifantsev/lg";
        lg.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { self, nixpkgs, ... }@args: {
        nixosModules.default = { pkgs, ... }: {
            nixpkgs.overlays = [(final: prev: {
                manager = self.packages.${final.system}.manager;
            })];

            environment.systemPackages = [
                pkgs.manager
            ];
        };

        packages = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (
            system: import ./package.nix args system
        );
    };
}

