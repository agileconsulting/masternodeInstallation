#!/bin/bash
#                   
# version 	0.4-alpha
# date    	2017-11-11
#
# function	masternode setup script
#			This scripts needs to be run as root to install all dependency for a masternode
# 			
#
# 	
#

# Useful variables
DATE_STAMP="$(date +%y-%m-%d-%s)"
MNODE_SWAPSIZE="5000"
SCRIPT_VERSION="0.4-beta"

function check_distro() {
	# currently only for Ubuntu 16.04
	if [[ -r /etc/os-release ]]; then
		. /etc/os-release
		if [[ "${VERSION_ID}" != "16.04" ]]; then
			echo "This script only supports ubuntu 16.04 LTS, exiting."
			exit 1
		fi
	else
		# no, thats not ok!
		echo "This script only supports ubuntu 16.04 LTS, exiting."	
		exit 1
	fi
}

function install_packages() {
	# development and build packages
	# these are common on all cryptos
	echo "Package installation!"
	apt-get -qq update
	apt-get -qqy -o=Dpkg::Use-Pty=0 install build-essential g++ \
	protobuf-compiler libboost-all-dev autotools-dev \
    automake libcurl4-openssl-dev libboost-all-dev libssl-dev libdb++-dev \
    make autoconf automake libtool git apt-utils libprotobuf-dev pkg-config \
    libcurl3-dev libudev-dev libqrencode-dev bsdmainutils pkg-config libssl-dev \
    libgmp3-dev libevent-dev jp2a
}

function swaphack() { 
#check if swap is available
if [ $(free | awk '/^Swap:/ {exit !$2}') ] || [ ! -f "/var/mnode_swap.img" ];then
	echo "No proper swap, creating it"
	# needed because ant servers are ants
	rm -f /var/mnode_swap.img
	dd if=/dev/zero of=/var/mnode_swap.img bs=1024k count=${MNODE_SWAPSIZE}
	chmod 0600 /var/mnode_swap.img
	mkswap /var/mnode_swap.img
	swapon /var/mnode_swap.img
	echo '/var/mnode_swap.img none swap sw 0 0' | tee -a /etc/fstab
	echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf
	echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf		
else
	echo "All good, we have a swap"	
fi
}


function configure_firewall() {
    echo "Configuring firewall rules"
	# disallow everything except ssh and masternode inbound ports
	ufw default deny
	ufw logging on
	# This will only allow 6 connections every 30 seconds from the same IP address.
	ufw limit OpenSSH	
	ufw --force enable 
}




main() {
    check_distro
    swaphack
    install_packages
	configure_firewall
}

main "$@"
