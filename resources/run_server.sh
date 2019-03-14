#!/bin/bash
set -e

trap 'exit 0' TERM INT  ## This line makes shutting down the container faster

sudo /etc/init.d/ssh start

tmux new-session -n Shell -s session1 -d
tmux new-window -t session1:1 -n Notebook -d "default_notebook; read"
tmux new-window -t session1:2 -n JupyterLab -d "default_jupyterlab; read"

if tty -s; then
    tmux attach-session -t session1
else
    sleep infinity
fi
