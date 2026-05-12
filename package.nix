{ nixpkgs, lg, ...}: system: let
    pkgs = import nixpkgs { inherit system; };
    lga = lg.packages.${system}.lga;
    lge = lg.packages.${system}.lge;

    build = name: { execer?[], inputs }: file: pkgs.resholve.writeScriptBin name {
        interpreter = "${pkgs.bash}/bin/bash";

        execer = execer ++ [
            "cannot:${lga}/bin/lga"
            "cannot:${lge}/bin/lge"
        ];

        inputs = inputs ++ [
            lga lge
            pkgs.coreutils
        ];
    } (builtins.readFile file);

    supervisor-daemon = build "supervisor-daemon" {
        inputs = [
            pkgs.gawk
            pkgs.gnused
            pkgs.jq
        ];
    } ./daemon.sh;
in {
    inherit supervisor-daemon;

    default = build "supervisor" {
        execer = [
            "cannot:${supervisor-daemon}/bin/supervisor-daemon"
        ];

        inputs = [
            supervisor-daemon
            pkgs.procps
            pkgs.inotify-tools
        ];
    } ./supervisor.sh;
}
