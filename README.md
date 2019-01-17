# ML-Dock
This is a general purpose machine learning docker image.

This docker image is based, among others, on the docker images from Jupyter Docker Stacks:
https://jupyter-docker-stacks.readthedocs.io/en/latest/


## Dependencies
- NVIDIA drivers of version 384.81 or higher
- Docker
- NVIDIA-Docker

For setting up the dependencies see the "*Installing dependencies*" section.

## Usage
### Running application with a graphical user interface
In order to by able to run application which have  a GUI (graphical user interface) the following command must
first be ran on the host machine:
``` bash
xhost +local:root
```
**!Security note**: Running this line create a security venerability which allows remote application on the
network to be able connect to the current machine's display. For safer, but more complex, solutions see 
http://wiki.ros.org/docker/Tutorials/GUI

### Running application using mldock
To create a container and run a single application inside it use:
``` bash
docker run [optional arguments] omeryair/mldock[:version_number] [command_to_run]
```

For a full list of optional arguments see https://docs.docker.com/engine/reference/commandline/run/.

Here is a short list of some useful arguments:

- *--rm*: Remove the container once the program running on it finishes.

- *-d*: Run the container in the background.

- *-it*: Enables interactive console when running console programs such as *bash*, *zsh*, *python console* etc.

- *--runtime=nvidia*: Run dockers using the NVIDIA-Docker engine which is required for using the GPU inside the 
container.

- *--network host*: Make programs running inside the container appear on the network as if they are running on
the host machine.  This is also true for programs which use ports on localhost such as *Jupyter Notebook*.

- *-e DISPLAY=${DISPLAY} -e MPLBACKEND=Qt5Agg -e QT_X11_NO_MITSHM=1 -v "/tmp/.X11-unix:/tmp/.X11-unix"*:
Maps the container graphic output to that of the host which enables running and interacting with GUI 
application inside the container such as *PyCharm*.

- *-v ~/workspace/:/app/workspace/*: Maps the */app/workspace/* folder inside the container to the
*~/workspace* folder on the host machine. *~/workspace/* and */app/workspace/* can be replaced be any other
desired pair of folder on the host and in the container respectively. See the *Mapping folders* section below.

- *-v ~/dockeruser_home/:/home/dockuser/*: Maps the home folder of the *dockuser* user (inside the container) to
the *~/dockuser_home* folder on the host machine. *~/dockuser_home* can be replaced by any other
desired folder. See the *Mapping the home folder* section below.

- *-v /media/:/media/*: Maps the */media* folder from the host machine to that of the container, which is where 
external storage devices are mounted on *Ubuntu* by default.

- *--name mldocker*: Set the container name to be *mldocker* instead of a random name. This makes it simpler to
address the container in other docker commands such as running a new command in an existing container.

"*command_to_run*" is the command line to run inside the container. Some useful examples:
- *bash*: Opens up a Bash console inside the container.
- *zsh*: Opens up a Zsh console inside the container.
- *reset_home_folder*: Resets the *dockuser*'s home folder. See the *Mapping the home folder* section bellow for
for details.
- *code*: Runs VSCode.
- *pycharm*: Runs pycharm.
- *run_server*: (Default) Runs a container with the following applications:
    - *Jupyter Notebook*: on port 9900
    - *JupyterHub*: on port 9901

If no *command_to_run* is supplied then the default command is used which is *run_server*.

### Examples
- Running the *reset_home_folder* command (see *Mapping the home folder* section):
``` bash
docker run \
    --rm \
    --runtime=nvidia \
    -v ~/dockuser_home/:/home/dockuser/ \
    --name mldock \
    omeryair/mldock reset_home_folder
```

- Running the default script (Jupyter Notebook + Hub) + mapping the home folder:
``` bash
docker run \
    --rm \
    --runtime=nvidia \
    --network host \
    -v ~/dockuser_home/:/home/dockuser/ \
    --name mldock \
    omeryair/mldock
```

- Open a bash console + mapping the home folder:
``` bash
docker run \
    --rm \
    -it \
    --runtime=nvidia \
    -v ~/dockuser_home/:/home/dockuser/ \
    --name mldock \
    omeryair/mldock bash
```

- Running *PyCharm* + mapping the home folder + mapping the */media/* folder:
``` bash
xhost +local:root
docker run \
    --rm \
    --runtime=nvidia \
    -e DISPLAY=${DISPLAY} \
    -e MPLBACKEND=Qt5Agg \
    -e QT_X11_NO_MITSHM=1\
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ~/dockuser_home/:/home/dockuser/ \
    -v /media/:/media/ \
    --name mldock \
    omeryair/mldock pycharm
```

- Starting a general purpose container in the background with all of the above arguments:
``` bash
xhost +local:root
docker run \
    --rm \
    -d \
    --runtime=nvidia \
    --network host \
    -e DISPLAY=${DISPLAY} \
    -e MPLBACKEND=Qt5Agg \
    -e QT_X11_NO_MITSHM=1\
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ~/dockuser_home/:/home/dockuser/ \
    --name mldock \
    omeryair/mldock
```

### Running command in an existing container
In addition, you can also run commands on an existing container using the following command:
``` bash
docker exec [-it] mldock [command_to_run]
```

## The *dockuser* user
The default user inside the container is *dockuser* which is part of the *dockuser* group. It has the randomly
selected the *uid* and *gid* of *4283:4283*.

## Permissions
New files created by the *dockuser* user will by default only have write permissions for this user and group.
This is guaranteed to create access permission problems when working on files and folder which are used both
on the host machine and inside the container. If running into such problems the following command can be used
for allowing permissions to a specific folder and it's content for everyone:
``` bash
sudo chmod a+rw -R {path_to_folder}
```

## Mapping the home folder
In general the run command starts a new fresh container each time with out any data from previous runs, except
from data which exists in folders in the container which are mapped to folders on the host machine (the *-v*
argument of the *run* command)

Since the console history and most of the user specific application configurations is stored in the user's home
folder, it is convenient to make this folder consistent between runs. This can be done using the
*-v ~/dockuser_home/:/home/dockuser/* flag (see above).

When running the command with this flag for the first time it is necessary to reset the home folder's content 
by running the *reset_home_folder* command.

**Note**: This command deletes all the data in the folder on the host machine which is mapped to the dockuser's
home folder and replaces is content with the default, so use this command with caution.


## Installing dependencies
### NVIDIA dirvers
This docker image uses CUDA 9.0 which requires NVIDIA drivers of version 384.81 or later.
(To fine the list of NVIDIA drivers version and CUDA version supported be your graphic card
go to: https://www.geforce.com/drivers)

For some reason installing NVIDIA drivers on Linux tend to cause problems, but in many cases the following
In some cases the following line would simply to the tick:
``` bash
sudo apt -y install nvidia-driver-{driver_version}
```

In the case where apt is not able to fine the desired driver try the following method:
1. Go to https://developer.download.nvidia.com/compute/cuda/repos/ and find the the link to the repository
installation file which fits the desired CUDA version and your system. It should be of the format of:
*https://developer.download.nvidia.com/compute/cuda/repos/{os_version}/{arch}/cuda-repo-{os_version}_{cuda_version}_{arch}.deb*
In addition find in the same folder the link to the repository keys, it should be a file of the format:
*https://developer.download.nvidia.com/compute/cuda/repos/{os_version}/{arch}/{some_number}.pub*

2. Run the following commands to install the NVIDIA drivers + CUDA
``` bash
cd /tmp
curl -L {link_to_the_repo_file_from_stage_1} -o cuda_installation.deb
sudo dpkg -i cuda_installation.deb
sudo apt-key adv --fetch-keys {link_to_the_key_file_from_stage_1}
sudo apt-get update
sudo apt-get install -y cuda
rm cuda_installation.deb
```
Example, installing CUDA 10.0 on Ubnutnu 18.04
``` bash
cd /tmp
curl -L wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb -o cuda_installation.deb
dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
apt-get update
apt-get install cuda -y
```

For more information you can look at the guides from NVIDIA website:
- CUDA installation guide: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html
- The quick start guide: https://docs.nvidia.com/cuda/cuda-quick-start-guide/index.html

### Docker
Install he latest docker version by following the instructions here:
https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository

To enable a user to run docker without the need to use *sudo* run the following command:
```
sudo usermod -aG docker {username}
```
Replace {username} with the name of the desired user. To apply this change you will need the user to logout
and back in again.

### NVIDIA docker
Install nvidia-docker by following the instructions here: https://github.com/NVIDIA/nvidia-docker

### Optional: docker-compose
Install docker compose by running the following commands:
``` bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Advance usage

### Building and pushing
Before pushing the image for the first time run:
``` bash
docker login
```

- To build and push the docker run:
``` bash
docker build -t omeryair/mkdock:{version_number} .
docker push omeryair/mkdock:{version_number}
```

### Docker Compose
Docker Compose, among others, allows you to write a YAML file defining the container we would like to run
along with it's arguments. The *docker-compose.yml* file in this repository is an example of such a file.

For running dockers with NVIDIA engine the following option must be added to the */etc/docker/daemon.json*
file: *"default-runtime": "nvidia"*. The following commands adds this line and restarts the docker service:
``` bash
sudo sed -i "2i \    \"default-runtime\": \"nvidia\"," /etc/docker/daemon.json
sudo pkill -SIGHUP dockerd
```

To run a docker container using docker-compose run:
``` bash
xhost +local:root
docker-compose up -d
```

This looks for a file named *docker-compose.yml* in the current directory and starts a container according to
the options in the file, running the default script.

To execute a new command on the running container run:
``` bash
docker-compose exec mldocker [command_to_run]
```

To bring the container down run
``` bash
docker-compose down
```

For more info see https://docs.docker.com/compose/
