export LGSTEM=supervisor

activity_file="/tmp/supervisor-activity"

lga start

function finish() { lga finish ; exit "$1"; }

function daemon_pid() { pgrep -f supervisor-daemon ; }

function start_daemon() {
    supervisor-daemon > /dev/null 2>&1 &
    disown
    echo "started daemon[$(daemon_pid)]"
}

function kill_daemon() {
    kill "$pid"
    echo "killing daemon[$pid]"
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
fi

if [ -z "$(daemon_pid)" ]; then
    echo "autostarting daemon"
    start_daemon
fi

case "$command" in
    "") cat "$activity_file"
        ;;
    onchange)
        if [ -n "$action" ] # timeout
        then inotifywait -e modify -t "$action" "$activity_file" &>/dev/null
        else inotifywait -e modify "$activity_file" &>/dev/null
        fi

        cat "$activity_file"
        ;;
    *) echo "unrecognized command[$command]"; finish 1 ;;
esac
