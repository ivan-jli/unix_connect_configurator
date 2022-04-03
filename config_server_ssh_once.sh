#!/bin/sh

# *** MIT License. 2022 Ivan Ivanov ***
# This script is used to automatically set up the ssh server on the Target computer (which is the machine the script has to be executed). In my usecase the Target is a Raspberry Pi Single-board Computer (SBC) with Raspbian (i. e. Debian GNU Linux).
# If everything works without problems, your Target won't need a monitor or a serial adapter at all. To proceed please execute the Instructions from this file on the Target. 
# Prerequisites: If you don't have (monitor and keyboard) on your Target, you will need a way to access the Target's filesystem directly (in SBC case - a card reader)
# No static IP configuration necessary, which makes the solution flexible.
#
#					      
#					      
#					      						
#				     --------------------				--------------------- 
#				     i	      	    	i				i		     i
#				     i	      	    	i				i		     i
#				     i	      	    	i				i		     i
#				     i	       	       	i                               i		     i------(INTERNET)
#				     i	       	    	i				i		     i
#				     i	Workstation     i				i       Target	     i
#				     --------------------      	       	       	       	----------------------
#				     (Example: Laptop)					(Example: SBC)	
#											This script has to be run once here, 
#											while the Target is connected to the Internet
#--------------------------------------------------------------------------------------------------------------------------------------------			
#  ... After running the script, the Target becames a SSH Server with Avahi Daemon enabled. 
#
#
##					      						
#				     --------------------				--------------------- 
#				     i	      	    	i				i		     i
#				     i	      	    	i				i    SSH Server      i
#				     i	      	    	i	Network connectivity    i                    i
#				     i	       	       	i------------------------------ i Bonjour	     i
#				     i	       	    	i				i		     i
#				     i	   Terminal     i				i IPv4 LL Address    i
#				     --------------------      	       	       	       	----------------------
#					terminal					  mysweetrpi 
#
#				     The corresponding program from				
#				     this suite has to be executed here	
#				     
#						<<<<< RESULT: >>>>					
#
#				     user@terminal:$ ./configureClient eth1
#                                    user@terminal:$ ssh pi@mysweetrpi.local
#                                    pi@mysweetrpi:$
#
#
#

#Instructions:
# If you don't have a monitor or keyboard/mouse on the Target, mount the Target filesystem on the "Terminal" computer
# Otherwise proceed directly on the Target - (use, for example, an USB Stick (or punched cards if you wish ;) ) to get the files there) 
# Copy this script together with the terminal's ssh public key on the Target under CONFIG_DIR (search this file for CONFIG_DIR)
# 
# Examples:
# DON'T BLINDLY COPY-PASTE! dd stands for 'disk destroyer' :) 
#
# sudo dd if=/home/terminal_pc/Resources/2022-01-28-raspios-bullseye-armhf-lite.img of=/terminal_pc/sdb bs=16M:
# ### Here we use CONFIG_DIR (search this file for CONFIG_DIR) on the Target filesystem to copy these 2 files:
# (if you don't have a connection to the internet over Ethernet, then you'll need wpa_supplicant.conf as well.
# sudo cp ~/.ssh/id_rsa.pub /media/terminal_pc/rootfs/srv/ ; sudo cp ~/Documents/unix_connect_configurator/config_server_ssh_once.sh /media/terminal_pc/rootfs/srv/ ; sudo cp ~/wpa_supplicant.conf /media/terminal_pc/rootfs/etc/wpa_supplicant/wpa_supplicant.conf #preppisd

#
# Add a line in FILE_THAT_INVOKES_THIS_SCRIPT : 
# After the script runs, this line will be deleted. THIS EXAMPLE UNBLOCKS the WLAN as well.
# sudo sed -ie "s/^exit 0$/rfkill unblock wlan ; dhclient wlan0 ; \/srv\/config_server_ssh_once.sh\nexit 0/g" /media/dev/rootfs/etc/rc.local
#
# user@terminal:$ sudo umount /mnt/target_fs 
# now you can eject the target_fs media (SD Card in the SBC case) and insert it into the Target so that it can boot from it. 
# Connect the Target to the internet and power it up.
#
# Resources: 
# https://wiki.archlinux.org/title/OpenSSH 
#
# Developer:
#Use the shellcheck utility or similar for static code analysis, if you don't feel like you're super pro..

#PARAMETERS
#not all symbols are supported; for example '_' is not (and giving a name 'my_server' will result in 'myserver')
SRV_NAME='mysweetrpi'
USER_NAME='pi'
# Target Filesystem - TARGET_FS='/' for production, something else for test. 
TARGET_FS='/'
# the name of the directory where the script was placed.
CONFIG_DIR='srv/'
NAME_OF_THE_PUBLIC_KEY_FILE='id_rsa.pub'
NAME_OF_THIS_SCRIPT='config_server_ssh_once.sh'

#VARIABLES
LOG_OUTPUT_DIR="${TARGET_FS}${CONFIG_DIR}log/"
FILE_THAT_INVOKES_THIS_SCRIPT="${TARGET_FS}etc/rc.local"
SSH_DIR="${TARGET_FS}home/${USER_NAME}/.ssh/"
SSHD_CONF="${TARGET_FS}etc/ssh/sshd_config"

#SCRIPT

if [ "$(id -u)" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#LOGGER
#  Finding or creating an empty directory (LOG_OUTPUT_DIR_DIR) inside LOG_OUTPUT_DIR, where the output from the current 
# script run, as well as a backup copy from the modified files, will be stored.

# you can place here a script which turns your wifi on. For ethernet, everything should work out of the box.
$(${TARGET_FS}${CONFIG_DIR}net/net_up.sh)

for i in $(seq 1 100);
do
	LOG_OUTPUT_DIR_DIR="${LOG_OUTPUT_DIR}config_server_ssh_once_${i}/"
	if [ -d "${LOG_OUTPUT_DIR_DIR}" ]; then
		if [ -z "$(ls -A "${LOG_OUTPUT_DIR_DIR}")" ]; then
			#dir exists and empty -> we'll use it for the logging
			break 
		else
			#dir exists but not empty -> incrementing the name
			continue
		fi
	else
		#dir not exist, creating one
		mkdir -p "${LOG_OUTPUT_DIR_DIR}"
		break
	fi
done

#Internet-dependent part: installing packages
if ! apt-get update; then
	echo "Problem connecting to the OS package manager repo. Please check the internet connectivity."
	ping -c 2 www.startpage.com
	exit 10
fi
apt-get install -y openssh-server 
apt-get install -y avahi-daemon 
apt-get install -y avahi-discover 
apt-get install -y libnss-mdns 
#at this point the openssh-server is installed, but not running. Editing the sshd_config 
# file backup


#the output from the following section is being logged
{
date
##adding the ssh key to the authorized keys
mkdir "${SSH_DIR}"
cat "${TARGET_FS}${CONFIG_DIR}${NAME_OF_THE_PUBLIC_KEY_FILE}" >> "${SSH_DIR}authorized_keys"
chown -R "${USER_NAME}" "${SSH_DIR}"
chmod 700 "${SSH_DIR}" 
chmod 600 "${SSH_DIR}authorized_keys" 
hostnamectl set-hostname "${SRV_NAME}"

cp "${SSHD_CONF}" "${LOG_OUTPUT_DIR_DIR}"

#if no line 'AuthenticationMethods publickey ... exists, write it
#strange, but AuthenticationMethods isn't understood.. sshd -T doesn't print it back.. 
if [ "$(grep -c "^AuthenticationMethods publickey" < "${SSHD_CONF}")" -eq 0 ]; then
	echo "AuthenticationMethods publickey" >> "${SSHD_CONF}"
fi
#making sure that after the replacement there is exactly one line [line_begin]AuthenticationMethods publickey[line_end]
#
sed -ie "s/^[#]\?\s*PasswordAuthentication\s*\w*\s*$/PasswordAuthentication no/g" "${SSHD_CONF}"
#making sure that after the replacement there is exactly one line [line_begin]AuthenticationMethods publickey[line_end]

#grep -c "^PasswordAuthentication no$" < "${SSHD_CONF}"  | { read -r lc; test "$lc" -eq 1 || exit 1; }

#if [ "$(sudo sshd -T |grep -cie "^passwordauthentication no$")" -lt 1 ]; then

#without this directory the next check would fail. Otherwise it's automatically created.
mkdir /run/sshd
if [ "$(sudo sshd -T |grep -cie "^passwordauthentication no$")" -lt 1 ] ; then
	echo "seems the sshd PasswordAuthentication setting wasn't correctly set. Exiting the script now without enabling sshd."
	exit 1
fi


#printing the difference after the replacement in the log
echo "the changes inside sshd_config are:"
diff "${LOG_OUTPUT_DIR_DIR}sshd_config" "${SSHD_CONF}"
echo "end of sshd_config changes"

systemctl enable ssh
systemctl enable avahi-daemon
sed -ie "/.*.${NAME_OF_THIS_SCRIPT}*/d" "${FILE_THAT_INVOKES_THIS_SCRIPT}" #deletes the line which has started this script
echo "${NAME_OF_THIS_SCRIPT} ended"
echo
echo
cat PEACE
} > "${LOG_OUTPUT_DIR_DIR}/log.txt"
# apt-get -y upgrade #todo move to a separate script
reboot
# rather unneccessary:
exit 0
