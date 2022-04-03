#!/bin/sh
# configure the client (ssh terminal) to be able to connect to the ssh server using zeroconf. 
# Input Parameters - interface name - the name of the network interface, which is connected to the server.
#
#TODO check manually the iptables and add eventually the necessary rules.
#
#iptables -F
#iptables -P INPUT ACCEPT
avahi-autoipd -D "$1"
systemctl start avahi-daemon
# problems acquiring IPv4 LL address (Debian Bullseye). Another problems I had with Fedora ?32.. 
# I don't know how this is supposed to work.. TODO 
sudo ifconfig "$1" 169.254.41.61

