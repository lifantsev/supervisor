{ lib, ... }: {
    enable = lib.mkEnableOption "setup of config.json and update-loop.sh";

    config = lib.mkOption {
        description = "attrset to populate config.json with";
        default = {};
        type = lib.types.attrs;
    };

    updateloop = lib.mkOption {
        description = "how to set up update-loop.sh";
        default = {};
        type = lib.types.submodule { options = {
            use = lib.mkOption {
                description = "use a premade script for update-loop instead of setting one yourself";
                type = lib.types.enum [ "" "niri" ];
                default = "";
                example = "niri";
            };

            sh = lib.mkOption {
                description = "update-loop.sh script, should output a line every time current activities should be rechecked";
                type = lib.types.str;
                default = "";
                example = ''
                    niri msg --json event-stream | jq --unbuffered -r 'select(has("WindowFocusChanged") or has("WindowOpenedOrChanged")) | "update"'
                '';
            };
        };};
    };
}
