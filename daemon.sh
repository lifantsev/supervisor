# WARN NO SPECIAL CHARS ALLOWED IN JSON NAMES
export LGSTEM=supervisor-daemon

activity_file="/tmp/supervisor-activity"
config_file="$XDG_CONFIG_HOME/supervisor/config.json"

function finish() { lga finish; exit "$1"; }

function json() {
    jq -r "$1" "$config_file"
}

function cfg() { # <activity> <key>
    json ".\"$1\".$2"
}

function any_hits() { # <str> <regexs>
    str="$1"
    regexs="$2"

    lga F "$(echo -e "any_hits() on str[$str] with regexs[[[\n$regexs\n]]]")"

    if echo "$regexs" | awk -v str="$str" '
        $0 != "" && str ~ $0 { found=1; exit } 
        END { exit !found }
        ';
    then lga . "got a match"; return 0
    else lga . "no matches"; return 1
    fi
}

function any_hits_json() { # <str> <key to regexs> <on_empty>
    str="$1"
    key="$2"
    on_empty="$3"

    lga F "any_hits_json() with str[$str] key[$key] on_empty[$on_empty]"

    json_type="$(json ".$key | type")"

    case "$json_type" in
        "string") regexs="$(json ".$key")" ;;
        "array") regexs="$(json ".$key.[]")" ;;
        "null") regexs="" ;;
        *)
            lge "any_hits_json() called with a key that's not a string or array"
            finish 1
            ;;
    esac

    if [ -z "$regexs" ]; then
        lga . "no regexs found, returning on_empty[$on_empty]"
        return "$on_empty"
    fi

    any_hits "$str" "$regexs"
}

function get_class() { # no args
    class="$(eval "$GET_WINDOW_CLASS")"

    browsers="$(echo "$BROWSER" ; echo "$BROWSERS")"
    browser_regexs="$(echo "$browsers" | sed -e 's|^|\^|' -e 's|$|\$|')"

    terminals="$(echo "$TERMINAL" ; echo "$TERMINALS")"
    terminal_regexs="$(echo "$terminals" | sed -e 's|^|\^|' -e 's|$|\$|')"

    if any_hits "$class" "$browser_regexs"; then echo "browser"; return; fi
    if any_hits "$class" "$terminal_regexs"; then echo "terminal"; return; fi

    echo "$class"
}

function get_title() {
    eval "$GET_WINDOW_TITLE"
}

function add_activity() { # <activity>
    lga . "adding activity[$1]"
    activities="$(echo "$1" ; echo "$activities")"
}

function process_activities() { # no args
    lga . "$(echo -e "process_activities[\n$activities\n]")"

    file_contents="$(cat "$activity_file")"

    if [ -z "$file_contents" ]; then
        if [ -z "$activities" ];
        then return 0
        else echo "$activities" > "$activity_file"
        fi
    else
        if [ -z "$activities" ];
        then echo -n > "$activity_file"
        elif [ "$activities" != "$file_contents" ]; then
            echo "$activities" > "$activity_file"
        fi
    fi
}

lga "starting the supervisor daemon"

while true; do
    sleep 1
    lga start
    activities=""

    lga . "getting class"
    class="$(get_class)"
    lga . "have class[$class]"

    if [ -z "$(json "to_entries | .[] | select(.key == \"$class\")")" ]
    then lga I "class[$class] is not registered in cfg..."; process_activities;  continue; fi

    add_activity "$class.any"

    if [ -z "$(json "to_entries | .[] | select(.key == \"$class\").value")" ]
    then lga I "class[$class] has no registered activities..."; process_activities;  continue; fi

    # only go thru activities if there are any
    title="$(get_title)"
    lga . "current class[$class], title[$title]"

    while IFS= read -r activity; do
        lga . "looking at registered activity[$activity]"

        json_type="$(cfg "$class" "$activity | type")"

        case "$json_type" in
            "string"|"array")
                if ! any_hits_json "$title" "$class.$activity" 0; then continue; fi
                add_activity "$class.$activity"
                ;;
            "object")
                if ! any_hits_json "$title" "$class.$activity.match" 0; then continue; fi
                if any_hits_json "$title" "$class.$activity.exclude" 1; then continue; fi
                add_activity "$class.$activity"
                ;;
        esac
    done <<< "$(json "to_entries | .[] | select(.key == \"$class\").value | to_entries.[].key")"

    process_activities

    lga finish
done
