# supervisor

Define activities by window class/title and shell scripts, then query the daemon to see what activities are currently active.

- [Usage](#Usage), [Configuration](#Configuration), [Installation](#Installation)

## Usage

queries (these autostart the daemon)
``` sh
supervisor # print out the current activities
|> browser.instagram

supervisor # print out the current activities
|> terminal.other

supervisor "onchange" # wait for current activities to change, then print the new ones
supervisor "onchange" <timeout> # only wait for <timeout> seconds before printing
```

daemon management
``` sh
supervisor "daemon" # start the daemon
supervisor "daemon" "kill" # kill the daemon
supervisor "daemon" "restart" # restart the daemon
supervisor "daemon" "pid" # print the pids of the daemon
```

## Configuration

### config.json

Set up activities in `$XDG_CONFIG_HOME/supervisor/config.json`. They are categorized by window class (`browser` and `terminal` are special cases determined using `$BROWSER` and `$TERMINAL`). Beyond that, activities can be defined as:
 - string: regex to match against the window title
 - list: list of regexs (only one needs to match)
 - object: can define these keys:
    - match: string or list of regexs to match
    - exclude: string or list of regexs to exclude
    - sh: a shellscript; if it exits successfully, the activity matches

There is also a special class `any`. Activities under this key will match regardless of window class.

Every class has an implicit activity `other`, which if matches the class matches but none of its activities do (ie `browser.other`). Note that `any.other` does not exist. In order to register a class without any activities, set the class key to an empty string.

``` json
{
    "mpv": "",
    "browser": {
        "instagram": {
            "match": [ "www.instagram.com", "reels" ],
            "exclude": "Messages"
        },
        "search": "www.google.com",
    },
    "terminal": {
        "editor": "^nvim",
        "files": "^lf"
    },
    "any": {
        "latetime": {
            "sh": "[ $(date +%H) -ge 22 ] || [ $(date +%H) -le 4 ]"
        }
    }
}
```

### update-loop.sh

Set up `$XDG_CONFIG_HOME/supervisor/update-loop.sh` to a script that is some sort of event stream. The supervisor will start the script and watch its output. Every time it prints a line, it will update the currently active activities.

``` sh
niri msg --json event-stream |
    jq --unbuffered -r 'select(has("WindowFocusChanged") or has("WindowOpenedOrChanged")) | "update"'
```

### home module

You can use the home module to set this stuff up too:

``` nix
# flake.nix
inputs.supervisor.url = "github:lifantsev/supervisor";

# home.nix
imports = [ inputs.supervisor.homeManagerModules.default ];

programs.supervisor = {
    enable = true;

    config = {
        any.latetime.sh = "[ $(date +%H) -ge 22 ] || [ $(date +%H) -le 4 ]";
    };

    # set the update script yourself
    updateloop.sh = /*sh*/ "while :; do sleep 1; echo update; done";

    # or use one of the premade scripts
    updateloop.use = "niri"; # use niri event stream
};
```

## Installation

### flake

``` nix
# flake.nix
inputs.supervisor.url = "github:lifantsev/supervisor";

# config.nix
imports = [ inputs.supervisor.nixosModules.default ]; # add pkgs.supervisor overlay & install the package

# or install without overlay
environment.systemPackages = [
    inputs.supervisor.packages.default
];
```

### other

If you are not a nix user, you can download the shellscripts and install them however you want. Note that `supervisor.sh` expects `daemon.sh` to be installed as `supervisord`. Also, the scripts depend on [lg](https://github.com/lifantsev/lg), remove any calls to `lga` and `lge` if you don't have those installed.
