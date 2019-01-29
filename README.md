# ML-Dock

A fully featured computer vision / machine learning development environment inside a Docker image.

The image contains:
- The basic Ubnutu development packages: build-essentianl, cmake, etc.
- Common management tools: git, curl, rsync, etc.
- Terminal based develop tools: vim, tmux, zsh, tig, etc.
- GUI based IDE / editors: PyCharm: and VSCode.
- Basic scientific Python packages: NumPy, SciPy, Pandas, etc.
- Python plotting packages: Matplotlib, Plotly, Seaboarn, etc.
- Computer vision and machine learning packages: OpenCV, SciKit-Image, SciKit-learn, etc.
- Deep learning frameworks: Tensorflow (CPU support only for now) and Torch (+ TorchVision)
- Jupyter notebook and JupyterLab

For a complete list of packages take a look at the Dockerfile

The goal of this project is to try and create a development environment which enjoys the benefits of developing
on top of Docker such as portability, reproducibility, versioning, confinement etc. while trying to make
working inside a Docker container seamless as possible.

*mldock* comes with a CLI tool (the *mldock.sh* file) for simplifying the work with the Docker image as a development
working environment. The CLI offers some short and simple commands for running commands in either a disposable or a 
consistent Docker container. 

The following features are enabled by default (and can be disabled using the appropriate flags):
- Allowing GUI based applications to run inside the container (mapping the host's X-Server into the container).
- Using the same user inside the Docker container as the user on the host machine (along with it's uid and gid).
- Mapping the entire host file system inside the container (at */host*).
- Sharing all network ports between the container and the host machine (using the *host* network driver)
- Using a consistent home folder (given a path to a folder on the host machine as an input).

**!!! An important security note**: For enabling the X-Server mapping the CLI uses the following command:
"*xhost +local:root*" which creates a potential security venerability (For more details see:
http://wiki.ros.org/docker/Tutorials/GUI). To disable the X-server mapping and avoid this security issue 
using the -x flag when running commands.

For a more detailed documentation then this readme see the docs folder.

## Dependencies
- Docker
- NVIDIA drivers of version 384.81 or higher
- NVIDIA-Docker

For setting these dependencies see the "*Installing dependencies*" section in documentation.

## Setup
A part from the above dependencies, the only necessary tool for using the *mldock* CLI is the *mldock.sh* file.
(The docker image itself is pulled from DockerHub on first usage). To download the file from github (along with
the rest of the repository) use:
``` bash
git clone https://github.com/yairomer/mldock.git {target_folder}
```

Then move into the repository's folder (the folder containing the *mldock.sh* file) and run the following command 
to define the *mldock* command shortcut:
```bash
./mldock.sh create_link
```
You will be ask to enter your user password.
(This command simply create a link to the *mldock.sh* file at */usr/bin/mldock*).

## Usage
From the output of *mldock -h*:
```
A CLI tool for working with the mldock docker

usage: mldock  <command> [<options>]
   or: mldock -h         to print this help message.

Commands
    create_link             Create a link to the mldock.sh script in the /usr/bin folder (requiers sudo).
    build                   Build the image.
    run                     Run a command inside a new container.
    exec                    Execute a command inside an existing container.
    stop                    Stop a running container.
Use mldock <command> -h for specific help on each command.
```

## Examples
To simply start a disposable container running a simple bash shell, run:
```bash
mldock run bash
```

---

In most cases you would probably want to keep our home folder consistent between runs. This is done using the
*-f {folder to use as home folder}* flag. If a non existing or empty folder is given, then it is initialized with
some initial home folder content. 

For example, to run PyCharm inside a container using the folder *~/mldock_home* as a permanent home folder run:
```bash
mldock run -f ~/mldock_home pycharm
```
You can even use your regular home folder for inside the container.

---

The image come with a default command which starts Jupyter notebook and JupyterLab (in a tmux session). To
run it simply run the container without any command:
```bash
mldock run -f ~/mldock_home
```

---

To run the container it in the background use the detach flag *-d*.
```bash
mldock run -d -f ~/mldock_home
```

And to stop a detach container run:
```bash
mldock stop
```

---

You can also run command on an existing container (for example a container with is currently running a notebook
server) using the *exec* command.

For example, to open VSCode in an existing container run:
```bash
mldock exec code
```

## Some notes
- By default, when starting a new container the current user on the host machine is recreated inside the container. 
Commands are then executed using this user. You can use the *-u* flag to use a default *dockuser* user instead, or 
the *-s* to use *root* user.

- By default, the CLI maps the */host* folder inside the container to the root folder (*/*) of the host
machine so that you could easily share file between the container and the host machine. To disable this mapping
use the *-r* flag.

- You can override the default command be placing a script file  in the folder which is used as the
container's home folder, and naming it *mldock_default_cmd.sh*.


Enjoy ;)
