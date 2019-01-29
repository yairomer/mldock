#!/bin/bash
set -e

trap 'exit 0' TERM INT  ## This line makes shutting down the container faster

tmux new-session -n Shell -s session1 -d
tmux new-window -t session1:1 -n Notebook -d "jupyter-notebook --port=9900 --notebook-dir=/ --ip=0.0.0.0 --NotebookApp.token='' --no-browser --allow-root --ContentsManager.allow_hidden=True --FileContentsManager.allow_hidden=True; read"
tmux new-window -t session1:2 -n JupyterLab -d "jupyter lab --port=9901 --notebook-dir=/ --ip=0.0.0.0 --NotebookApp.token='' --no-browser --allow-root; read"

if tty -s; then
    tmux attach-session -t session1
else
    sleep infinity
fi
