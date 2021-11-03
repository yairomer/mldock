#!/bin/bash
set -e

trap 'shutdown' TERM INT  ## This line makes shutting down the container faster

if [ "$#"  -gt 0 ]; then
    cmd=("$@")
else
    cmd=("bash")
fi

if [ ! -z "$SSHPORT" ]; then
    sed 's/^#\?Port .*$/Port '"$SSHPORT"'/g' -i /etc/ssh/sshd_config
    /etc/init.d/ssh restart > /dev/null 2>&1
fi

if [ ! -z "$SSHKEY" ]; then
    mkdir /root/.ssh
    echo "${SSHKEY//  /$'\n'}" > /root/.ssh/id_rsa.mldock
    chmod 400 /root/.ssh/id_rsa.mldock
    echo "IdentityFile ~/.ssh/id_rsa.mldock" >> /root/.ssh/config
fi

if [ ! -z "$SSHFSDIRS" ]; then
    IFS=',' read -ra SSHFSDIRS <<< "$SSHFSDIRS"
    for map in "${SSHFSDIRS[@]}"; do
        IFS=';' read -ra map <<< "$map"
        if [[ ! -d "${map[1]}" ]]; then
            mkdir -p ${map[1]}
            chmod 777 ${map[1]}
        fi
        sshfs -o allow_other -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${map[0]} ${map[1]}
    done
fi

if [ ! -z "$USERSTRING" ]; then
    IFS=':' read -ra USERSTRINGSPLIT <<< "$USERSTRING"

    new_username="${USERSTRINGSPLIT[0]}"
    new_uid=${USERSTRINGSPLIT[1]}
    new_groupname="${USERSTRINGSPLIT[2]}"
    new_gid=${USERSTRINGSPLIT[3]}

    echo "$new_username" > /tmp/dock_config/username

    if [[ ! $new_username == "root" ]]; then
        if ! id $new_uid > /dev/null 2>&1; then
            ## User does not exist. Create user
            if [[ -z $(getent group $new_gid) ]]; then
                ## Group does not exist. Create group
                groupadd -g $new_gid "$new_groupname"
            else
                ## Group exist. Check that the group's name matches
                if [[ ! $(getent group $new_gid | awk -F ":" '{ print $1 }') == "$new_groupname" ]]; then
                    echo "!! Error: A group with the gid of \"$new_gid\" but with a different group name already exist: \"$(getent group $new_gid | awk -F ":" '{ print $1 }')\""
                    exit 1
                fi
            fi

            new_shell="/bin/bash"
            if [[ ! -d "/home/$new_username"  ]]; then
                echo "-> Creating user's home folder."
                home_folder_arg="--create-home"
            else
                home_folder_arg="--home /home/$new_username"
                if [[ -f "/home/$new_username/.zshrc" ]]; then
                    ## Assume the user prefers Zsh as his shell
                    new_shell="/bin/zsh"
                fi
            fi
            useradd --system $home_folder_arg --shell $new_shell -G sudo -G video -g $new_gid -u $new_uid $new_username
            echo "$new_username ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$new_username
            # mkdir /tmp/runtime-$new_username
            # chown $new_username:$new_groupname /tmp/runtime-$new_username
        else
            ## User exist. Check that the user's name matches
            if [[ ! $(id -un $new_uid) == "$new_username" ]]; then
                echo "!! Error: A user with the uid of \"$new_uid\" but with a different user name already exist: \"$(id -un $new_uid)\""
                exit 1
            fi

            ## User exist. Check that the gid matches
            if [[ ! $(id -g $new_uid) == $new_gid ]]; then
                echo "!! Error: A user with the uid of \"$new_uid\" but with a different gid already exist: \"$(id -g $new_uid)\""
                exit 1
            fi

            ## User exist. Check that the group's name matches
            if [[ ! $(id -gn $new_uid) == "$new_groupname" ]]; then
                echo "!! Error: A user with the uid of \"$new_uid\" but with a different group name already exist: \"$(id -gn $new_uid)\""
                exit 1
            fi
        fi
    
        if [[ -z "$(ls -A /home/$new_username)" ]]; then
            echo "-> Reseting user's home folder."
            cp -rT /etc/skel/. /home/$new_username/
            chown $new_username:"$new_groupname" -R /home/$new_username
        fi

        if [[ "$(pwd)" == "/root" ]]; then
            cd /home/$new_username
        fi

        if [[ ! -z "$WORKINGFOLDER" && -d "$WORKINGFOLDER" ]]; then
            cd $WORKINGFOLDER
        fi

        ln -sfT /home/$new_username/dockvenv /app/dockvenv
        if [ "$#" -gt 0 ]; then
            runuser -u $new_username -- "${cmd[@]}"
        else
            if [[ -f /home/$new_username/default_cmd.sh ]]; then
                runuser -u $new_username /home/$new_username/default_cmd.sh
            else
                su $new_username
            fi
        fi
    else
        if [ ! -z "$WORKINGFOLDER" ]; then
            cd $WORKINGFOLDER
        fi
        "$cmd"
    fi
else
    if [ ! -z "$WORKINGFOLDER" ]; then
        cd $WORKINGFOLDER
    fi
    "$cmd"
fi