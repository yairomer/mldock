#!/bin/bash
set -e

## Main CLI function
## =================
app_name=mldock

repository="omeryair/"
image_name="mldock"
version_name="v0.2"

container_name="mldock"

main_cli() {
    ## Parse args
    ## ==========
    usage() {
        echo "A CLI tool for working with the mldock docker"
        echo ""
        echo "usage: $app_name  <command> [<options>]"
        echo "   or: $app_name -h         to print this help message."
        echo ""
        echo "Commands"
        echo "    add_to_bin              Create a link to the mldock.sh script in the /usr/bin folder (requiers sudo)."
        echo "    build                   Build the image."
        echo "    run                     Run a command inside a new container."
        echo "    exec                    Execute a command inside an existing container."
        echo "    stop                    Stop a running container."
        echo "Use $app_name <command> -h for specific help on each command."
    }
    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts ":h" opt; do
        case $opt in
            h )
                usage
                exit 0
                ;;
            \? )
                echo "Error: Invalid Option: -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -lt 1 ]; then
        echo "Error: Was expecting a command" 1>&2
        usage
        exit 1
    fi

    subcommand=$1; shift

    case "$subcommand" in
        add_to_bin)
            add_to_bin_cli "$@"
            ;;
        build)
            build_cli "$@"
            ;;
        run)
            run_cli "$@"
            ;;
        exec)
            exec_cli "$@"
            ;;
        stop)
            stop_cli "$@"
            ;;
        *)
            echo "Error: unknown command $subcommand" 1>&2
            usage
            exit 1
    esac
}

add_to_bin_cli() {
    usage () {
        echo "Create a link to the mldock.sh script in the /usr/bin folder (Requires sudo)."
        echo ""
        echo "usage: $app_name $subcommand"
        echo "   or: $app_name $subcommand -h    to print this help message."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi

    add_to_bin
}

build_cli() {
    tag_as_latest=true
    usage () {
        echo "Build the image"
        echo ""
        echo "usage: $app_name $subcommand [<options>]"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -v version_name         The version name to use for the build image. Default: \"$version_name\""
        echo "    -l                      Don't tag built image as latest"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "v:l" opt; do
        case $opt in
            v)
                version_name=$OPTARG
                ;;
            l)
                tag_as_latest=false
                ;;
            :)
                echo "Error: -$OPTARG requires an argument" 1>&2
                usage
                exit 1
                ;;
            \?)
                echo "Error: unknown option -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi

    build_image
}

run_cli() {
    if xhost >& /dev/null ; then
        ## Display exist
        connect_to_x_server=true
    else
        ## No display
        connect_to_x_server=false
    fi
    userstring="$(whoami):$(id -u):$(id -gn):$(id -g)"
    map_host=true
    detach_container=false
    home_folder=""
    command_to_run="default_cmd"
    extra_args=""
    if nvidia-smi >& /dev/null ; then 
        use_nvidia_runtime=true
    else
        use_nvidia_runtime=false
    fi
    usage () {
        echo "Run a command inside a new container"
        echo ""
        echo "usage: $app_name $subcommand [<options>] [command]"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -v version_name         The version name to use for the build image. Default: \"$version_name\""
        echo "    -c container_name       The name to for the created container. Default: \"$container_name\""
        echo "    -f home_folder          A folder to map as the dockuser's home folder."
        echo "    -s                      Run the command as root."
        echo "    -u                      Run the command as dockuser user."
        echo "    -x                      Don't connect X-server"
        echo "    -r                      Don't map the root folder on the host machine to /host inside the container."
        echo "    -d                      Detach the container."
        echo "    -e extra_args           Extra arguments to pass to the docker run command."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "v:c:f:suxrde:" opt; do
        case $opt in
            v)
                version_name=$OPTARG
                ;;
            c)
                container_name=$OPTARG
                ;;
            f)
                home_folder=$OPTARG
                ;;
            s)
                userstring=""
                ;;
            u)
                userstring="dockuser:4283:dockuser:4283"
                ;;
            x)
                connect_to_x_server=false
                ;;
            r)
                map_host=false
                ;;
            d)
                detach_container=true
                ;;
            e)
                extra_args=$OPTARG
                ;;
            :)
                echo "Error: -$OPTARG requires an argument" 1>&2
                usage
                exit 1
                ;;
            \?)
                echo "Error: unknown option -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        command_to_run=( "$@" )
    fi

    run_command
}

exec_cli() {
    username="$(whoami)"
    extra_args=""
    command_to_run="tmux attach-session -t session1"
    usage () {
        echo "Execute a command inside an existing container"
        echo ""
        echo "usage: $app_name $subcommand [<options>] [command_to_run]"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -c container_name       The name to for the created container. default: \"$container_name\""
        echo "    -u username             The user to use for running the command. default: \"$username\""
        echo "    -e extra_args           Extra arguments to pass to the docker exec command."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "c:u:e:" opt; do
        case $opt in
            c)
                container_name=$OPTARG
                ;;
            u)
                username=$OPTARG
                ;;
            e)
                extra_args=$OPTARG
                ;;
            :)
                echo "Error: -$OPTARG requires an argument" 1>&2
                usage
                exit 1
                ;;
            \?)
                echo "Error: unknown option -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        command_to_run=( "$@" )
    fi

    exec_command
}

stop_cli() {
    usage () {
        echo "Stop a running container."
        echo ""
        echo "usage: $app_name $subcommand"
        echo "   or: $app_name $subcommand -h    to print this help message."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi

    stop_container
}

mldock_dir="$( cd $( dirname "$(readlink ${BASH_SOURCE[0]})" ) && pwd )"
# mldock_dir="$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )"

add_to_bin() {
    echo "-> Creating a symbolic link to $mldock_dir/mldoc.sh at /usr/bin/mldock"

    sudo ln -sfT $mldock_dir/mldock.sh /usr/bin/mldock
}

build_image() {
    echo "-> Building image from $mldock_dir"

    docker build -t $repository$image_name:$version_name $mldock_dir

    if [ "$tag_as_latest" = true ]; then
        docker tag $repository$image_name:$version_name $repository$image_name:latest
    fi
}

run_command() {
    # # if [ "user_host_user" = true ]; then
    # if [ true = true ]; then
    #     extra_args="-v /etc/passwd:/etc/passwd -u $(id -u ${USER}):$(id -g ${USER})"
    # fi

    if [ "$connect_to_x_server" = true ]; then
        xhost +local:root > /dev/null
        extra_args="$extra_args -e DISPLAY=${DISPLAY} -e MPLBACKEND=Qt5Agg -e QT_X11_NO_MITSHM=1 -v /tmp/.X11-unix:/tmp/.X11-unix"
    fi

    if [ "$map_host" = true ]; then
        extra_args="$extra_args -v /:/host/"
    fi

    if [[ ! -z $home_folder && ! -z $userstring ]]; then
        userstringsplit=(${userstring//:/ })
        new_username=${userstringsplit[0]}

        extra_args="$extra_args -v $home_folder:/home/$new_username/"
    fi

    if [ "$detach_container" = true ]; then
        extra_args="$extra_args -d"
    else
        extra_args="$extra_args -it"
    fi

    if [ "$use_nvidia_runtime" = true ]; then
        extra_args="$extra_args --runtime=nvidia"
    fi

    docker run \
        --rm \
        --network host \
        --name $container_name \
        -e USERSTRING=$userstring \
        $extra_args \
        $repository$image_name:$version_name "${command_to_run[@]}"
}

exec_command() {
    if [[ ! -z $username ]]; then
        extra_args="$extra_args -u $username"
    fi

    docker exec -it $extra_args $container_name $command_to_run
}


stop_container() {
    echo "-> Stopping the container"
    docker stop $container_name
}

main_cli "$@"
