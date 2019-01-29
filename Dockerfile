FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
# FROM nvidia/cuda:9.2-cudnn7-devel-ubuntu18.04

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
        man \
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
    apt-get install -y neovim && \
    pip install pynvim==0.3.2 && \
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
COPY ./resources/pycharm.bin /usr/local/bin/pycharm

## Setup app folder
## ================
RUN mkdir /app && \
    chmod 777 /app

## Setup python environment
## ========================
RUN sudo -H pip3 install -U virtualenv==16.2.0 && \
    virtualenv /app/venv && \
    export PATH="/app/venv/bin:$PATH" && \
    pip3 install pip==18.1 && \
    hash -r pip && \
    pip3 install -U \
        ipython==7.0.1 \
        numpy==1.15.2 \
        scipy==1.1.0 \
        matplotlib==3.0.0 \
        PyQt5==5.11.3 \
        seaborn==0.9.0 \
        plotly==3.5.0 \
        bokeh==1.0.4 \
        ggplot==0.11.5 \
        altair==2.3.0 \
        pandas==0.23.4 \
        pyyaml==3.13 \
        protobuf==3.6.1 \
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
        jupyterlab==0.4.0 \
        ipywidgets==7.4.2 \
        && \
    chmod a=u -R /app/venv
ENV PATH="/app/venv/bin:$PATH"
ENV MPLBACKEND=Agg

## Import matplotlib the first time to build the font cache.
## ---------------------------------------------------------
RUN python -c "import matplotlib.pyplot" && \
    cp -r /root/.cache /etc/skel/

## Setup Jupyter
## -------------
RUN jupyter nbextension enable --py widgetsnbextension && \
    jupyter contrib nbextension install --system && \
    jupyter nbextensions_configurator enable && \
    jupyter serverextension enable --py jupyterlab --system && \
    cp -r /root/.jupyter /etc/skel/

## Install dumb-init
## =================
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb
RUN dpkg -i dumb-init_*.deb

## Apply home folder patch to update pycharm's setting
## ===================================================
## Patch was created using the following commands:
##     cd /home
##     sudo mv dockuser dockuser_new
##     cp -rp /app/backup/dockuser_home /home/dockuser
##     diff -ruN dockuser/ dockuser_new/ > /tmp/pycharm_home_folder.patch
COPY ./resources/pycharm_home_folder.patch /app/patches/pycharm_home_folder.patch

RUN echo "#!/bin/bash\ncd /home\npatch -s -p0 < /app/patches/pycharm_home_folder.patch" | sudo tee /usr/local/bin/apply_pycharm_patch && \
    sudo chmod a+x /usr/local/bin/apply_pycharm_patch && \
    apply_pycharm_patch

## Set default environment variables
## =================================
ENV NOTEBOOK_PORT="9900"
ENV NOTEBOOK_ARGS="--notebook-dir=/ --ip=0.0.0.0 --NotebookApp.token='' --no-browser --allow-root --ContentsManager.allow_hidden=True --FileContentsManager.allow_hidden=True"
ENV NOTEBOOK_EXTRA_ARGS=""
ENV JUPYTERLAB_PORT="9901"
ENV JUPYTERLAB_ARGS="--notebook-dir=/ --ip=0.0.0.0 --NotebookApp.token='' --no-browser --allow-root"
ENV JUPYTERLAB_EXTRA_ARGS=""
## Copy scripts
## ============
COPY /resources/entrypoint.sh /app/scripts/entrypoint.sh
COPY /resources/default_cmd.sh /app/scripts/default_cmd.sh
RUN chmod a=u -R /app/scripts && \
    echo "#!/bin/bash\nset -e\nexec /app/scripts/entrypoint.sh \"\$@\"" > /usr/local/bin/run && \
    chmod a+x /usr/local/bin/run && \
    echo "#!/bin/bash\nset -e\nif [[ -f \$HOME/mldock_default_cmd.sh ]]; then exec \$HOME/mldock_default_cmd.sh \"\$@\"; else exec /app/scripts/default_cmd.sh \"\$@\"; fi" > /usr/local/bin/default_cmd && \
    chmod a+x /usr/local/bin/default_cmd && \
    cp /app/scripts/default_cmd.sh /etc/skel/mldock_deafult_cmd.sh

## Create dockuser user
## ====================
ARG DOCKUSER_UID=4283
ARG DOCKUSER_GID=4283
RUN groupadd -g $DOCKUSER_GID dockuser && \
    useradd --system --create-home --home /home/dockuser --shell /bin/bash -G sudo -g dockuser -u $DOCKUSER_UID dockuser && \
    mkdir /tmp/runtime-dockuser && \
    chown dockuser:dockuser /tmp/runtime-dockuser && \
    echo "dockuser ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/dockuser

WORKDIR /root
ENTRYPOINT ["/usr/bin/dumb-init", "--", "run"]
