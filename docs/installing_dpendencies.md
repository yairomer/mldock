# Installing dependencies

## NVIDIA dirvers
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

## Docker
Install he latest docker version by following the instructions here:
https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository

To enable a user to run docker without the need to use *sudo* run the following command:
```
sudo usermod -aG docker {username}
```
Replace {username} with the name of the desired user. To apply this change you will need the user to logout
and back in again.

## NVIDIA docker
Install nvidia-docker by following the instructions here: https://github.com/NVIDIA/nvidia-docker
