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
                supervisor = self.packages.${final.system}.supervisor;
            })];

            environment.systemPackages = [
                pkgs.supervisor
            ];
        };

        packages = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (
            system: import ./package.nix args system
        );

        homeManagerModules.default = hmargs: {
            options.programs.supervisor = import ./options.nix hmargs;
            config = import ./config.nix hmargs;
        };
    };
}

