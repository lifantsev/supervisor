{ nixpkgs, lg, ...}: system: let
    pkgs = import nixpkgs { inherit system; };
    lga = lg.packages.${system}.lga;
    lge = lg.packages.${system}.lge;

    build = name: { inputs, execer?[], keep?{} }: pkgs.resholve.writeScriptBin name {
        interpreter = "${pkgs.bash}/bin/bash";

        inherit keep;

        execer = execer ++ [
            "cannot:${lga}/bin/lga"
            "cannot:${lge}/bin/lge"
        ];

        inputs = inputs ++ [
            lga lge
            pkgs.coreutils
        ];
    } (builtins.readFile (./. + "/${name}.sh"));

    supervisord = build "supervisord" {
        keep.source = [ "$updateloop_sh" ];

        inputs = [
            pkgs.gawk
            pkgs.gnused
            pkgs.jq
        ];
    };

    supervisor = build "supervisor" {
        execer = [
            "cannot:${supervisord}/bin/supervisord"
        ];

        inputs = [
            supervisord
            pkgs.procps
            pkgs.inotify-tools
        ];
    };
in {
    inherit supervisor supervisord;

    default = supervisor;
}
