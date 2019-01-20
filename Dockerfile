FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
# FROM nvidia/cuda:9.2-cudnn7-devel-ubuntu18.04

USER root

## Install basic packages and useful utilities
## ===========================================
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:neovim-ppa/stable && \
    apt-get update -y && \
    apt-get install -y \
        build-essential \
        bzip2 \
        ca-certificates \
        locales \
        fonts-liberation \
        cmake \
        sudo \
        python3 \
        python3-dev \
        python3-pip \
        python \
        python-dev \
        python-pip \
        sshfs \
        wget \
        curl \
        rsync \
        ssh \
        nano \
        vim \
        neovim \
        emacs \
        git \
        tig \
        tmux \
        zsh \
        unzip \
        htop \
        tree \
        silversearcher-ag \
        ctags \
        cscope \
        libblas-dev \
        liblapack-dev \
        gfortran \
        libfreetype6-dev \
        libpng-dev \
        ffmpeg \
        python-qt4 \
        python3-pyqt5 \
        imagemagick \
        inkscape \
        jed \
        libsm6 \
        libxext-dev \
        libxrender1 \
        lmodern \
        netcat \
        pandoc \
        texlive-fonts-extra \
        texlive-fonts-recommended \
        texlive-generic-recommended \
        texlive-latex-base \
        texlive-latex-extra \
        texlive-xetex \
        graphviz \
        && \
    apt-get clean

    ## ToDo: increase memory limit to 10GB in: /etc/ImageMagick-6/policy.xml

## Set locale
## ==========
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

## VSCode
## ======
RUN cd /tmp && \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get install apt-transport-https && \
    apt-get update && \
    apt-get install -y code && \
    rm microsoft.gpg

## Install pycharm
## ===============
ARG PYCHARM_SOURCE="https://download.jetbrains.com/python/pycharm-community-2018.3.3.tar.gz"
RUN mkdir /opt/pycharm && \
    cd /opt/pycharm && \
    curl -L $PYCHARM_SOURCE -o installer.tgz && \
    tar --strip-components=1 -xzf installer.tgz && \
    rm installer.tgz && \
    /usr/bin/python2 /opt/pycharm/helpers/pydev/setup_cython.py build_ext --inplace && \
    /usr/bin/python3 /opt/pycharm/helpers/pydev/setup_cython.py build_ext --inplace
COPY ./pycharm.bin /usr/local/bin/pycharm

## Create dockuser user
## ====================
ARG DOCKUSER_UID=4283
ARG DOCKUSER_GID=4283
RUN groupadd -g $DOCKUSER_GID dockuser && \
    useradd --system --create-home --shell /bin/bash -G sudo -g dockuser -u $DOCKUSER_UID dockuser && \
    echo "dockuser ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/dockuser
USER dockuser

## Setup app folder
## ================
RUN sudo mkdir /app && \
    sudo chown dockuser:dockuser /app

## Setup python environment
## ========================
RUN sudo -H pip3 install -U virtualenv && \
    virtualenv /app/venv --no-site-packages && \
    . /app/venv/bin/activate && \
    pip3 install pip==18.1 && \
    hash -r pip && \
    pip3 install -U \
        ipython==7.0.1 \
        numpy==1.15.2 \
        scipy==1.1.0 \
        matplotlib==3.0.0 \
        pandas==0.23.4 \
        pyyaml==3.13 \
        ipdb==0.11 \
        flake8==3.5.0 \
        cython==0.28.5 \
        sympy==1.3 \
        nose==1.3.7 \
        jupyter==1.0.0 \
        sphinx==1.8.1 \
        tqdm==4.27.0 \
        opencv-contrib-python==3.4.3.18 \
        scikit-image==0.14.1 \
        scikit-learn==0.20.0 \
        imageio==2.4.1 \
        torchvision==0.2.1 \
        tensorflow==1.12.0 \
        tensorboardX==1.4 \
        jupyter==1.0.0 \
        jupyterthemes==0.19.6 \
        jupyter_contrib_nbextensions==0.5.0 \
        jupyterlab==0.4.0
ENV PATH="/app/venv/bin:$PATH"
ENV MPLBACKEND=Agg

# RUN pip install seaborn, bokeh, protobuf, ipywidgets==7.4.2
RUN . /app/venv/bin/activate && \
    jupyter nbextension enable --py widgetsnbextension && \
    jupyter contrib nbextension install --user && \
    jupyter nbextensions_configurator enable && \
    jupyter serverextension enable --py jupyterlab --user

## Import matplotlib the first time to build the font cache.
# ENV XDG_CACHE_HOME /home/dockuser/.cache/
# RUN . /app/venv/bin/activate && \
#     python -c "import matplotlib.pyplot"

## Backup dockuser's home folder
## =============================
RUN mkdir /app/backups && \
    rsync -a /home/dockuser/ /app/backups/dockuser_home/ && \
    echo "#!/bin/bash\nset -e\nsudo rsync -a --del /app/backups/dockuser_home/ /home/dockuser/" | sudo tee /usr/local/bin/reset_home_folder && \
    sudo chmod a+x /usr/local/bin/reset_home_folder
    
## copy scripts
## ============
COPY /run_server.sh /app/scripts/run_server.sh

## Set default environment variables
## =================================
ENV NOTEBOOK_PORT="7600"
ENV NOTEBOOK_ARGS="--notebook-dir=/ --ip=0.0.0.0 --NotebookApp.token='' --no-browser --allow-root --ContentsManager.allow_hidden=True --FileContentsManager.allow_hidden=True"
ENV NOTEBOOK_EXTRA_ARGS=""
ENV JUPYTERLAB_PORT="7601"
ENV JUPYTERLAB_ARGS="--notebook-dir=/ --ip=0.0.0.0 --NotebookApp.token='' --no-browser --allow-root"
ENV JUPYTERLAB_EXTRA_ARGS=""

WORKDIR /home/dockuser/
CMD ["/app/scripts/run_server.sh"]
