#!/bin/bash
set -e
trap 'exit 0' TERM INT  ## This line makes shutting down the container faster

if [ -z "$NOTEBOOKPORT" ]; then
    NOTEBOOKPORT=9900
fi
if [ -z "$NOTEBOOKARGS" ]; then
    NOTEBOOKAEGS="--port=$NOTEBOOKPORT --notebook-dir=/ --ip=0.0.0.0 --NotebookApp.token='' --no-browser --allow-root --ContentsManager.allow_hidden=True --FileContentsManager.allow_hidden=True $NOTEBOOKARGSEXTRA"
fi
jupyter-notebook $NOTEBOOKAEGS
