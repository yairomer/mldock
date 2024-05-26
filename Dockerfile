FROM nvidia/cuda:11.3.0-cudnn8-devel-ubuntu20.04

## Install basic packages and useful utilities
## ===========================================
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y  && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:flexiondotorg/nvtop && \
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
        openssh-server \
        python3.8 \
        python3.8-dev \
        python3-pip \
        pylint \
        sshfs \
        wget \
        curl \
        rsync \
        ssh \
        bc \
        nano \
        vim \
        emacs \
        git \
        tig \
        tmux \
        zsh \
        unzip \
        htop \
        nvtop \
        tree \
        silversearcher-ag \
        ctags \
        cscope \
        jq \
        libblas-dev \
        liblapack-dev \
        gfortran \
        libfreetype6-dev \
        libpng-dev \
        ffmpeg \
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
        texlive-latex-base \
        texlive-latex-extra \
        texlive-science \
        texlive-xetex \
        latexmk \
        graphviz \
        libncurses5-dev \
        libncursesw5-dev \
        && \
    apt-get install -y neovim && \
    pip3 install pynvim==0.3.2 && \
    apt-get clean

## Increase memory limit of IamgeMagick to 10GB
## ============================================
RUN sed "s/<policy domain=\"resource\" name=\"memory\" value=\"256MiB\"\/>/<policy domain=\"resource\" name=\"memory\" value=\"10GiB\"\/>/g" /etc/ImageMagick-6/policy.xml 

## Set locale
## ==========
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

## SSH server
## ==========
RUN mkdir /var/run/sshd && \
    sed 's/^#\?PasswordAuthentication .*$/PasswordAuthentication yes/g' -i /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "user_allow_other" >> /etc/fuse.conf

## Setup app folder
## ================
RUN mkdir /app && \
    chmod 777 /app

## Setup python environment
## ========================
RUN python3.8 -m pip install pip==22.3.1 && \
    python3.8 -m pip install -U \
        cvxpy==1.2.2 \
        dash==2.7.1 \
        datasets==2.8.0 \
        filelock==3.8.2 \
        flake8==6.0.0 \
        Flask==2.2.2 \
        ggplot==0.11.5 \
        graphviz==0.20.1 \
        h5py==3.7.0 \
        imageio==2.23.0. \
        ipdb==0.13.11 \
        ipython==8.7.0 \
        ipywidgets==8.0.4 \
        jupyter==1.0.0 \
        jupyter-contrib-nbextensions==0.7.0 \
        jupyterlab==3.5.2 \
        jupyterthemes==0.20.0 \
        kaleido==0.2.1 \
        line-profiler==4.0.2 \
        lxml==4.9.2 \
        matplotlib==3.6.2 \
        nbconvert==7.2.7 \
        nose==1.3.7 \
        numpy==1.24.1 \
        opencv-contrib-python==4.6.0.66 \
        pandas==1.5.2 \
        Pillow==9.3.0 \
        plotly==5.11.0 \
        pylint==2.15.9 \
        PyQt5==5.14.1 \
        PyYAML==6.0 \
        scikit-image==0.19.3 \
        scikit-learn==1.2.0 \
        scipy==1.9.3 \
        seaborn==0.12.1 \
        six==1.16.0 \
        Sphinx==5.3.0 \
        sympy==1.11.1 \
        tensorflow-gpu==2.11.0 \
        torchaudio==0.13.1 \
        torchinfo==1.7.1 \
        torchsummary==1.5.1 \
        torchvision==0.14.1 \
        tqdm==4.64.1 \
        transformers==4.25.1 \
        virtualenv==20.17.1 \
        visdom==0.2.3 \
        wandb==0.13.5 \
        && \
        rm -r /root/.cache/pip
ENV MPLBACKEND=Agg

## Import matplotlib the first time to build the font cache.
## ---------------------------------------------------------
RUN python3.8 -c "import matplotlib.pyplot" && \
    cp -r /root/.cache /etc/skel/

## Setup Jupyter
## -------------
RUN jupyter nbextension enable --py widgetsnbextension && \
    jupyter contrib nbextension install --system && \
    jupyter nbextensions_configurator enable && \
    jupyter serverextension enable --py jupyterlab --system && \
    python3.8 -m pip install RISE && \
    jupyter-nbextension install rise --py --sys-prefix --system && \
    cp -r /root/.jupyter /etc/skel/

## Create virtual environment
## ==========================
RUN cd /app/ && \
    virtualenv --python=python3.8 --system-site-packages /app/dockvenv && \
    grep -rlnw --null /usr/local/bin/ -e '#!/usr/bin/python3.8' | xargs -0r cp -t /app/dockvenv/bin/ && \
    sed -i "s/#"'!'"\/usr\/bin\/python3.8/#"'!'"\/usr\/bin\/env python/g" /app/dockvenv/bin/* && \
    mv /app/dockvenv /root/ && \
    ln -sfT /root/dockvenv /app/dockvenv && \
    cp -rp /root/dockvenv /etc/skel/ && \
    sed -i "s/^\(PATH=\"\)\(.*\)$/\1\/app\/dockvenv\/bin:\2/g" /etc/environment
ENV PATH=/app/dockvenv/bin:$PATH
    # virtualenv dockvenv && \

## Node.js
## =======
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g grunt-cli

## Install dumb-init
## =================
RUN cd /tmp && \
    wget -O dumb-init.deb https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb && \
    dpkg -i dumb-init.deb && \
    rm dumb-init.deb

## Create container config file
## ============================
RUN mkdir /tmp/dock_config && \
    chmod a+wrx /tmp/dock_config

## Copy scripts
## ============
RUN mkdir /app/bin && \
    chmod a=u -R /app/bin && \
    sed -i "s/^\(PATH=\"\)\(.*\)$/\1\/app\/bin:\2/g" /etc/environment
ENV PATH="/app/bin:$PATH"
COPY /resources/switch_user_run.sh /app/bin/switch_user_run
COPY /resources/default_notebook.sh /app/bin/default_notebook
COPY /resources/default_jupyterlab.sh /app/bin/default_jupyterlab
COPY /resources/run_server.sh /app/bin/run_server
COPY /resources/run_in_detached_tmux.sh /app/bin/run_in_detached_tmux

RUN touch /etc/skel/.sudo_as_admin_successful

## Create dockuser user
## ====================
ARG DOCKUSER_UID=4283
ARG DOCKUSER_GID=4283
RUN groupadd -g $DOCKUSER_GID dockuser && \
    useradd --system --create-home --home /home/dockuser --shell /bin/bash -G sudo -g dockuser -u $DOCKUSER_UID dockuser && \
    mkdir /tmp/runtime-dockuser && \
    chown dockuser:dockuser /tmp/runtime-dockuser && \
    echo "dockuser ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/dockuser

ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8  

WORKDIR /root
ENTRYPOINT ["/usr/bin/dumb-init", "--", "switch_user_run"]
