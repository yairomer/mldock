FROM nvidia/cuda:11.0-cudnn8-devel-ubuntu18.04

## Install basic packages and useful utilities
## ===========================================
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y  && \
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
        texlive-xetex \
        graphviz \
        libncurses5-dev \
        libncursesw5-dev \
        && \
    apt-get install -y neovim && \
    pip3 install pynvim==0.3.2 && \
    apt-get clean

    ## ToDo: increase memory limit to 10GB in: /etc/ImageMagick-6/policy.xml

## Install nvtop
## =============
RUN git clone https://github.com/Syllo/nvtop.git /tmp/nvtop && \
    mkdir /tmp/nvtop/build && \
    cd /tmp/nvtop/build && \
    cmake .. || : && \
    make || : && \
    make install || : && \
    cd / && \
    rm -r /tmp/nvtop

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

## Setup app folder
## ================
RUN mkdir /app && \
    chmod 777 /app

## Setup python environment
## ========================
RUN python3.8 -m pip install pip==21.0.1 && \
    python3.8 -m pip install wrapt --ignore-installed && \
    python3.8 -m pip install -U \
        altair==4.1.0 \
        bokeh==2.3.1 \
        chainer==7.7.0 \
        cvxpy==1.1.12 \
        dash==1.20.0 \
        filelock==3.0.12 \
        flake8==3.9.1 \
        Flask==1.1.2 \
        ggplot==0.11.5 \
        graphviz==0.16 \
        h5py==2.10.0 \
        imageio==2.9.0 \
        ipdb==0.13.7 \
        ipython==7.22.0 \
        ipywidgets==7.6.3 \
        jupyter==1.0.0 \
        jupyter-contrib-nbextensions==0.5.1 \
        jupyterlab==3.0.14 \
        jupyterthemes==0.20.0 \
        kaleido==0.2.1 \
        line-profiler==3.2.1 \
        lxml==4.6.3 \
        matplotlib==3.4.1 \
        nbconvert==6.0.7 \
        nose==1.3.7 \
        numpy==1.19.5 \
        opencv-contrib-python==4.5.1.48 \
        pandas==1.2.4 \
        Pillow==8.2.0 \
        plotly==4.14.3 \
        protobuf==3.15.8 \
        pylint==2.8.2 \
        PyQt5==5.15.4 \
        PyYAML==5.4.1 \
        scikit-image==0.18.1 \
        scikit-learn==0.24.2 \
        scipy==1.6.3 \
        seaborn==0.11.1 \
        Sphinx==3.5.4 \
        sympy==1.8 \
        tensorboardX==2.2 \
        tensorflow-gpu==2.4.1 \
        torchaudio==0.8.1 \
        torchsummary==1.5.1 \
        torchvision==0.9.1 \
        torchviz==0.0.2 \
        tqdm==4.60.0 \
        virtualenv==20.4.4 \
        visdom==0.1.8.9 \
        && \
        rm -r /root/.cache/pip
ENV MPLBACKEND=Agg

## Import matplotlib the first time to build the font cache.
## ---------------------------------------------------------
RUN python3.8 -c "import matplotlib.pyplot" && \
    cp -r /root/.cache /etc/skel/

## Setup Jupyter
## -------------
RUN python3.8 -m pip install six==1.11 && \
    jupyter nbextension enable --py widgetsnbextension && \
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
    sed -i "s/^\(PATH=\"\)\(.*\)$/\1\/app\/dockvenv\/bin\/:\2/g" /etc/environment
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
    sed -i "s/^\(PATH=\"\)\(.*\)$/\1\/app\/bin\/:\2/g" /etc/environment
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
