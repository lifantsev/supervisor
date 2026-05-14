export LGSTEM=supervisor

activity_file="/tmp/supervisor-activities"

lga start

function finish() { lga finish ; exit "$1"; }

function daemon_pid() { pgrep supervisord ; }

function start_daemon() {
    supervisord > /dev/null 2>&1 &
    disown
    echo "started daemon[$(daemon_pid)]"
}

function kill_daemon() {
    kill $pid
    echo "killing daemon"
}

command="${1:-}"
action="${2:-}"

if [ "$command" == "daemon" ]; then
    pid="$(daemon_pid)"

    if [ -n "$pid" ]; then # daemon running
        case "$action" in
            pid) echo "$pid" ;;
            kill) kill_daemon ;;
            restart) kill_daemon ; start_daemon ;;
            "") echo "daemon is already running with pid[$pid]" ;;
            *) echo "unrecognized daemon action[$action]"; finish 1 ;;
        esac
    else # daemon NOT running
        case "$action" in
            "") start_daemon ;;
            restart) start_daemon ;;
            kill) echo "daemon is not running" ;;
            pid) echo "daemon is not running" ; finish 1 ;;
            *) echo "unrecognized daemon action[$action]"; finish 1 ;;
        esac
    fi

    finish 0
fi

autostart_daemon=0
[ -z "$(daemon_pid)" ] && autostart_daemon=1

if ((autostart_daemon)); then
    lga . "auto starting daemon"
    start_daemon &>/dev/null
fi

case "$command" in
    "") 
        if (( autostart_daemon )); then
            lga . "waiting for daemon to touch activity file"
            inotifywait -t 1 "$activity_file" &>/dev/null
            lga . "finished waiting"
        fi

        lga . "catting activity file[$activity_file]"
        cat "$activity_file"
        ;;
    onchange)
        lga . "waiting for daemon to modify activity file"
        if [ -n "$action" ] # timeout
        then inotifywait -e modify -t "$action" "$activity_file" &>/dev/null
        else inotifywait -e modify "$activity_file" &>/dev/null
        fi

        lga . "finished waiting, catting activity file[$activity_file]"
        cat "$activity_file"
        ;;
    *) echo "unrecognized command[$command]"; finish 1 ;;
esac
