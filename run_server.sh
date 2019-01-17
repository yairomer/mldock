#!/bin/bash

trap 'exit 0' TERM INT
tmux new-session -s session1 -d
tmux new-window -n Notebook -d -t 1 "jupyter-notebook --port=$NOTEBOOK_PORT $NOTEBOOK_ARGS $NOTEBOOK_EXTRA_ARGS; read"
tmux new-window -n JupyterLab -d -t 2 "jupyter lab --port=$JUPYTERLAB_PORT $JUPYTERLAB_ARGS $JUPYTERLAB_EXTRA_ARGS; read"
while true; do sleep infinity & wait ${!}; done
