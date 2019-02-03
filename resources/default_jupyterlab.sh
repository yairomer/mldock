#!/bin/bash
set -e
trap 'exit 0' TERM INT  ## This line makes shutting down the container faster

if [ -z "$JUPYTERLABPORT" ]; then
    JUPYTERLABPORT=9901
fi
if [ -z "$JUPYTERLABARGS" ]; then
    JUPYTERLABARGS="--port=$JUPYTERLABPORT --notebook-dir=/ --ip=0.0.0.0 --NotebookApp.token='' --no-browser --allow-root $JUPYTERLABARGSEXTRA"
fi
jupyter lab $JUPYTERLABARGS
