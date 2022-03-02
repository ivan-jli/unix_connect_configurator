#!/bin/sh
#####
#this script configures the host to make it able to be used as a remote console (ssh client), connecting to the target (ssh-server) using a name instead of an address AND allowing a direct ad-hoc Ethernet connection, without having the need to configure the interfaces manually.

IFACE="eth1"
#parsing arguments
while [ "$1" != "" ]; do
    PARAM=$(echo "$1" | awk -F= '{print $1}')
    VALUE=$(echo "$1" | awk -F= '{print $2}')
    echo "Param = $PARAM"
    echo "Value = $VALUE"
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -i | --interface)
            IFACE=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
	    echo "expected -i=interface - the network interface name of the adapter, connected to the Server"
            exit 1
            ;;
    esac
    shift
done

echo "Attach the network card to the machine and to the network or directly to the host"
echo "Press any key to continue"
read
#todo - add a rule only for mDNS
iptables -F
iptables -P INPUT ACCEPT
echo "iptables flushed"
avahi-autoipd -D "$IFACE"
#todo report success with &&
echo "avahi-autoipd started for $IFACE, thus allowing link-local automatic address assignment"
systemctl start avahi-daemon
echo "avahi-daemon started"


