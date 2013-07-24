#!/bin/sh

####################################################
############# Customize Stuff HERE #################
####################################################

############################## IMPORTANT - WARNING! #################################################
######                                                                                         ######
###### If you're not using some of these definitions, put a # in front of it                   ###### 
###### Also, don't forget the lines in the actual IPTables down below, block them with #!      ######
######                                                                                         ######
############################## IMPORTANT - WARNING! #################################################

#### Your default SSH Port (Can also be used for FTP)
SSH_PORT="22:23"

#### Your GameServer Ports (This will take care of RCON Blocks and Invalid Packets.
GAMESERVERPORTS="27015:27016"

#### Your home IP, this is only for remote RCON through HLSW, as you can use the !rcon command on the server as admin. (http://www.whatismyip.com/)
YOUR_HOME_IP="13.37.733.137"

#### Any additional Machines/Users you'd like to allow unlimited access to the Machine the server is hosted on.
#### I personally allow the Machine that controls Sourcebans, this prevents the need to open and rate limit MySQL ports.\
#### Remove "#" here and also in the IPTable rules below
# WHITELISTED_IPS="733.1.13.337"

#### UDP Ports you want to protect, feel free to remove 3306 (MySQL) and 64738 (Mumble) if you don't use them.
#### Add GameServers too, in case a flood of valid packets comes in

#### To add a Port Range use ":", Example; "27015:27022" 
#### You can add port ranges and single Ports together as well, Example; "27015:27022,80"
UDP_PORTS_PROTECTION="27015:27016"

#### TCP Ports you want to protect (Remove the # if you wish to protect a few Ports, also remove the # in the actual IPTables below.

#### To add a Port Range use ":", Example; "27015:27022" 
#### You can add port ranges and single Ports together as well, Example; "27015:27022,80"
# TCP_PORTS_PROTECTION=""

##########################################################
############# Customization Stuff ENDS HERE ##############
##########################################################

###################################################################################################################
# _|___|___|___|___|___|___|___|___|___|___|___|___|                                                             ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__        IPTables: Linux's Main line of Defense               ##
# _|___|___|___|___|___|___|___|___|___|___|___|___|        IPTables: Linux's way of saying no to DoS kids       ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__                                                             ##    
# _|___|___|___|___|___|___|___|___|___|___|___|___|        Version 1.0.1 -                                      ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__        IPTables Script created by Sir                       ##
# _|___|___|___|___|___|___|___|___|___|___|___|___|                                                             ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__        Sources used and Studied;                            ##
# _|___|___|___|___|___|___|___|___|___|___|___|___|                                                             ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__  http://ipset.netfilter.org/iptables.man.html               ##
# _|___|___|___|___|___|___|___|___|___|___|___|___|  https://forums.alliedmods.net/showthread.php?t=151551      ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__  http://www.cyberciti.biz/tips/linux-iptables-examples.html ##
###################################################################################################################

## Cleanup Rules First!
##--------------------
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
iptables -X
##--------------------

## Policies
##--------------------
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
##--------------------

## Create Filter
##---------------------
iptables -N filter
iptables -N LOGINVALID
iptables -N LOGFLOOD
##---------------------

## Create Filter Rules
##---------------------
iptables -A filter -m state --state NEW -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 5 --hashlimit-mode srcip,dstport --hashlimit-name DOSPROTECT --hashlimit-htable-expire 3600000 -j ACCEPT
iptables -A LOGINVALID -m limit --limit 60/min -j LOG --log-prefix "Invalid Packets Dropped: " --log-level 4
iptables -A LOGFLOOD -m limit --limit 60/min -j LOG --log-prefix "Valid Packets (Flood) Dropped: " --log-level 4
iptables -A LOGINVALID -j DROP
iptables -A LOGFLOOD -j DROP


# Allow Self
iptables -A INPUT -i lo -j ACCEPT

# Allow Whitelisted IPs
# iptables -A INPUT -s $WHITELISTED_IPS

# Accept Established Connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Block Packets ranging from 0:28, 30:32, 46 and 2521:65535 (Never Used, thus Invalid Packets) - This will catch all DoS attempts and Invalid Packet (weak) DDoS attacks as well.
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 0:28 -j LOGINVALID
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 30:32 -j LOGINVALID
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 46 -j LOGINVALID
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 2521:65535 -j LOGINVALID

# Rate Limit
iptables -A INPUT -p udp -m multiport --dports $UDP_PORTS_PROTECTION -j filter
iptables -A INPUT -p udp -m multiport --dports $UDP_PORTS_PROTECTION -j LOGFLOOD
# iptables -A INPUT -p tcp -m multiport --dports $TCP_PORTS_PROTECTION -j filter


#
# Rcon Usage - Only allow your own IP!
# Whitelisting is much more effective than limiting it, as it can still be abused, so please get yourself a Static IP.
# Admins can use !rcon on the server, so this is mainly for remote managing (HLSW)

iptables -A INPUT -p tcp -m multiport --dports $GAMESERVERPORTS -s $YOUR_HOME_IP -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports $GAMESERVERPORTS -j DROP

# SSH
iptables -A INPUT -p tcp --dport $SSH_PORT -s $YOUR_HOME_IP -j ACCEPT
iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 20 --hashlimit-mode srcip,dstport --hashlimit-name SSHPROTECT --hashlimit-htable-expire 3600000 -j ACCEPT

## Drop everything else!
##--------------------
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP
iptables -A OUTPUT -j ACCEPT
##--------------------