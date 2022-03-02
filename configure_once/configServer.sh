#!/bin/sh
#this script is used to automatically set up the ssh server on the target
#To use the script, copy it together with the ssh public key on the target under CONFIG_DIR 
#example script invoke from /etc/rc.local: 
# /srv/./configServer.sh >> /srv/debugOutput-configServer #placed, obviously, before the 'exit 0'
#The public key of the ssh client should be placed in CONFIG_DIR directory and named id_rsa.pub
#TODO disable password login

#PARAMETERS
SRV_NAME='my_raspberry'
USER_NAME='pi'
#
TARGET_FS=''
CONFIG_DIR='/srv'

#VARIABLES
SSH_DIR="$TARGET_FS/home/$USER_NAME/.ssh"

#SCRIPT
##adding the ssh key to the authorized keys
mkdir "$SSH_DIR"
cat "$CONFIG_DIR/id_rsa.pub" >> "$SSH_DIR/authorized_keys"
chown -R "$USER_NAME" "$SSH_DIR"
chmod -R 600 "$SSH_DIR" 
hostnamectl set-hostname "$SRV_NAME"
#Internet-dependent part: installing packages
apt update
apt install -y openssh-server avahi-daemon avahi-discover libnss-mdns 
systemctl enable ssh
systemctl enable avahi-daemon
exit 0

