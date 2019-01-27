#!/bin/bash
set -e

## Main CLI function
## =================
app_name=mldock

repository="omeryair/"
image_name="mldock"
version_name="latest"

container_name="mldock"

main_cli() {
    ## Parse args
    ## ==========
    usage() {
        echo "A CLI tool for working with the mldok docker"
        echo ""
        echo "usage: $app_name  <command> [<options>]"
        echo "   or: $app_name -h         to print this help message."
        echo ""
        echo "Commands"
        echo "    add_to_bin              Create a link to the mldock.sh script in the /usr/bin folder (requiers sudo)."
        echo "    build                   Build the image"
        echo "    run                     Run a command inside a new container"
        echo "    exec                    Execute a command inside an existing container"
        echo "    stop                    Stop a running container"
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
            add_to_bin_cli $@
            ;;
        build)
            build_cli $@
            ;;
        run)
            run_cli $@
            ;;
        exec)
            exec_cli $@
            ;;
        stop)
            stop_cli $@
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
        echo "usage: $app_name $subcommand [<options>] version"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    version_name            The version name to use for the build image"
        echo "    -l                      Don't tag built image as latest"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "ac" opt; do
        case $opt in
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

    if [ "$#" -lt 1 ]; then
        echo "Error: Was expecting a version name" 1>&2
        usage
        exit 1
    fi
    version_name=$1; shift

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi

    build_image
}

run_cli() {
    connect_to_x_server=false
    map_home=false
    map_host=false
    detach_container=false
    dockuser_home=""
    command_to_run=""
    extra_args=""
    usage () {
        echo "Run a command inside a new container"
        echo ""
        echo "usage: $app_name $subcommand [<options>] [command]"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -v version_name         The version name to use for the build image. default: \"$version_name\""
        echo "    -c container_name       The name to for the created container. default: \"$container_name\""
        echo "    -x                      Connect X-server"
        echo "    -u                      Map the users home folder inside the container (at the same location)."
        echo "    -r                      Map the root folder on the host machine to /host inside the container."
        echo "    -d                      Detach the container."
        echo "    -n dockuser_home        A folder to map as the dockuser's home folder."
        echo "    -e extra_args           Extra arguments to pass to the docker run command."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "v:c:xurdn:e:" opt; do
        case $opt in
            v)
                verasion_name=$OPTARG
                ;;
            c)
                container_name=$OPTARG
                ;;
            x)
                connect_to_x_server=true
                ;;
            u)
                map_home=true
                ;;
            r)
                map_host=true
                ;;
            d)
                detach_container=true
                ;;
            n)
                dockuser_home=$OPTARG
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
        command_to_run=$1; shift
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi

    run_command
}

exec_cli() {
    extra_args=""
    command_to_run="tmux attach-session -t session1"
    usage () {
        echo "Execute a command inside an existing container"
        echo ""
        echo "usage: $app_name $subcommand [<options>] [command_to_run]"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -c container_name       The name to for the created container. default: \"$container_name\""
        echo "    -e extra_args           Extra arguments to pass to the docker exec command."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "c:e:" opt; do
        case $opt in
            c)
                container_name=$OPTARG
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
        command_to_run=$1; shift
    fi

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
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

create_dockuser_home() {
    echo "-> Creating the dockuser home folder at \"$dockuser_home\""

    docker run --rm -v $dockuser_home/:/home/dockuser/ $repository$image_name:$version_name reset_home_folder
    docker run --rm -v $dockuser_home/:/home/dockuser/ $repository$image_name:$version_name apply_pycharm_patch
}

run_command() {
    echo "-> Running a command inside a new container"

    if [ "$connect_to_x_server" = true ]; then
        xhost +local:root
        extra_args="$extra_args -e DISPLAY=${DISPLAY} -e MPLBACKEND=Qt5Agg -e QT_X11_NO_MITSHM=1 -v /tmp/.X11-unix:/tmp/.X11-unix"
    fi

    if [ "$map_host" = true ]; then
        extra_args="$extra_args -v /:/host/"
    fi

    if [ "$map_home" = true ]; then
        extra_args="$extra_args -v $HOME/:$HOME/"
    fi

    if [ ! -z $dockuser_home ]; then
        if [ ! -d $dockuser_home ]; then
            create_dockuser_home
        fi
        extra_args="$extra_args -v $dockuser_home/:/home/dockuser/"
    fi

    if [ "$detach_container" = true ]; then
        extra_args="$extra_args -d"
    else
        extra_args="$extra_args -it"
    fi

    docker run \
        --rm \
        --runtime=nvidia \
        --network host \
        --name $container_name \
        $extra_args \
        $repository$image_name:$version_name $command_to_run

        # -v ~/dockuser_home/:/home/dockuser/ \
}

exec_command() {
    echo "-> Executing command on a existing container"
    docker exec -it $extra_args $container_name $command_to_run
}


stop_container() {
    echo "-> Stopping the container"
    docker stop $container_name
}

main_cli $@
