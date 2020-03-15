#!/bin/bash
set -e

if [ "$#"  -gt 0 ]; then
    cmd=("$@")
else
    cmd=("bash")
fi

trap 'exit 0' TERM INT  ## This line makes shutting down the container faster

tmux new-session -n run_window -s run_session -d "${cmd[@]}"
tmux set-hook -t run_session session-closed "wait-for -S finished"
tmux wait-for finised
