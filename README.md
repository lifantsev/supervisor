# supervisor

Define activities by window class/title and shell scripts, then query the daemon to see what activities are currently active.

- [Usage](#Usage), [Configuration](#Configuration), [Installation](#Installation)

## Quick Start

## Usage

queries (these autostart the daemon)
``` sh
supervisor # print out the current activities
|> browser.any
|> browser.instagram

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

Every class has an implicit activity `any`, which matches as long as the class matches (ie `browser.any`). Note that `any.any` does not exist, because it would be redundant. In order to just include `<class>.any` and not register any other activities, set the class key to an empty string.

``` json
{
    "mpv": "",
    "browser": {
        "instagram": {
            "match": [ "www.instagram.com", "reels" ],
            "exclude": "Messages"
        },
        "search": "www.google.com",
        "youtube": "www.youtube.com"
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

### flake

## Installation
