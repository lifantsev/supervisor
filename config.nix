{ lib, config, ... }: let
    cfg = config.programs.supervisor;

    script = if cfg.updateloop.use == "niri"
        then "niri msg --json event-stream | jq --unbuffered -r 'select(has(\"WindowFocusChanged\") or has(\"WindowOpenedOrChanged\")) | \"update\"'"
        else cfg.updateloop.sh;
in lib.mkIf cfg.enable
(lib.mkMerge [
    {
        xdg.configFile."supervisor/config.json".text = builtins.toJSON cfg.config;
        xdg.configFile."supervisor/update-loop.sh".text = script;
    }

    (lib.mkIf cfg.spawn-at-startup.niri {
        programs.niri.settings.spawn-at-startup = [ { argv = [ "supervisor" "daemon" ];} ];
    })
])

