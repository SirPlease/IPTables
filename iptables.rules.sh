#!/bin/sh

##/////// -----------------------------------------------------------------------------------------------------
##/////// ############################## IMPORTANT - WARNING! #################################################
##/////// ######                                                                                         ######
##/////// ###### If you're not using some of these definitions, put a # in front of it                   ###### 
##/////// ###### Also, don't forget the lines in the actual IPTables down below, block them with #!      ######
##/////// ######                                                                                         ######
##/////// ############################## IMPORTANT - WARNING! #################################################
##/////// -----------------------------------------------------------------------------------------------------


####################################################
############# Customize Stuff HERE #################
####################################################


#### Your default SSH Port (Can also be used for FTP)
SSH_PORT="21:23"

#### Your GameServer Ports (This will take care of RCON Blocks and Invalid Packets.
GAMESERVERPORTS="27015:27016"

#### Your home IP, this is only for remote RCON through HLSW, as you can use the !rcon command on the server as admin. (http://www.whatismyip.com/)
#### Remember to scroll down further and add a # in front of the lines that use YOUR_HOME_IP if you're not going to use this.
YOUR_HOME_IP="xxx.xxx.xxx.xxx"

#### Any additional Machines/Users you'd like to allow unlimited access to the Machine the server is hosted on.
#### Remember to scroll down further and remove the # in front of the lines that use WHITELISTED_IPS if you're going to use this
# WHITELISTED_IPS="xxx.xxx.xxx.xxx"

#### UDP Ports you want to protect, 3306 (MySQL) and 64738 (Mumble) are commonly used here.
#### Add GameServers too, in case a flood of valid packets comes in (Slipped past defence)
#### To add a Port Range use ":", Example; "27015:27022" 
#### You can add port ranges and single Ports together as well, Example; "27015:27022,80"
UDP_PORTS_PROTECTION="27015:27016"

#### TCP Ports you want to protect (Remove the # if you wish to protect a few Ports, also remove the # in the actual IPTables below.
#### To add a Port Range use ":", Example; "27015:27022" 
#### You can add port ranges and single Ports together as well, Example; "27015:27022,80"

########## Remember to scroll down further and remove the # in front of the lines that use TCP_PORTS_PROTECTION if you're going to use this.
# TCP_PORTS_PROTECTION="64738"

##########################################################
############# Customization Stuff ENDS HERE ##############
##########################################################

###################################################################################################################
# _|___|___|___|___|___|___|___|___|___|___|___|___|                                                             ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__        IPTables: Linux's Main line of Defense               ##
# _|___|___|___|___|___|___|___|___|___|___|___|___|        IPTables: Linux's way of saying no to DoS kids       ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__                                                             ##    
# _|___|___|___|___|___|___|___|___|___|___|___|___|        Version 1.0.2 -                                      ##
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
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
##--------------------

## Policies
##--------------------
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
##--------------------

## Create Filters
##---------------------
iptables -N UDPfilter
iptables -N TCPfilter
iptables -N LOGINVALID
iptables -N LOGFRAGMENTED
iptables -N LOGTCP
iptables -N LOGBANNEDIP
##---------------------

## Create Filter Rules
##---------------------
iptables -A UDPfilter -m state --state NEW -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 5 --hashlimit-mode srcip,dstport --hashlimit-name UDPDOSPROTECT --hashlimit-htable-expire 60000 --hashlimit-htable-max 999999999 -j ACCEPT
iptables -A TCPfilter -m state --state NEW -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 5 --hashlimit-mode srcip,dstport --hashlimit-name TCPDOSPROTECT --hashlimit-htable-expire 60000 --hashlimit-htable-max 999999999 -j ACCEPT
iptables -A LOGINVALID -m limit --limit 60/min -j LOG --log-prefix "Invalid Packets Dropped: " --log-level 4
iptables -A LOGFRAGMENTED -m limit --limit 60/min -j LOG --log-prefix "Frag Packets Dropped: " --log-level 4
iptables -A LOGTCP -m limit --limit 60/min -j LOG --log-prefix "Malformed/Spam TCP Dropped: " --log-level 4
iptables -A LOGBANNEDIP -m limit --limit 60/min -j LOG --log-prefix "Dropped Banned IP: " --log-level 4
iptables -A LOGINVALID -j DROP
iptables -A LOGBANNEDIP -j DROP
iptables -A LOGFRAGMENTED -j DROP
iptables -A LOGTCP -j DROP

#### Allow Self
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -s $YOUR_HOME_IP -j ACCEPT

#### Allow Whitelisted IPs
# iptables -A INPUT -s $WHITELISTED_IPS -j ACCEPT

#### Block Packets ranging from 0:28, 30:32, 46 and 2521:65535 (Never Used, thus Invalid Packets) - This will catch all DoS attempts and Invalid Packet (weak) DDoS attacks as well.
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 0:28 -j LOGINVALID
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 30:32 -j LOGINVALID
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 46 -j LOGINVALID
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 60 -j LOGINVALID
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 2521:65535 -j LOGINVALID

#### Block Fragmented Packets
#### Keep in mind that if your Linux Server acts as a router that this can affect a few things badly, I'd suggest removing/commenting this out if this is the case.
iptables -A INPUT -f -j LOGFRAGMENTED

#### Block ICMP/Pinging
iptables -A INPUT -p icmp -j DROP

#### Accept Established Connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#### Block Malformed/Null TCP Packets while forcing new connections to be SYN Packets
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j LOGTCP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j LOGTCP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j LOGTCP

#### Rate Limit & Uncomment TCP when used.
iptables -A INPUT -p udp -m multiport --dports $UDP_PORTS_PROTECTION -j UDPfilter
# iptables -A INPUT -p tcp -m multiport --dports $TCP_PORTS_PROTECTION -j TCPfilter

#### SSH && Home IP if Used.
# iptables -A INPUT -p tcp --dport $SSH_PORT -s $YOUR_HOME_IP -j ACCEPT
iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 20 --hashlimit-mode srcip,dstport --hashlimit-name SSHPROTECT --hashlimit-htable-expire 60000 --hashlimit-htable-max 999999999 -j ACCEPT

## Drop everything else!
##--------------------
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP
iptables -A OUTPUT -j ACCEPT
##--------------------

############ EXTRA STUFF TO HELP HIGH TRAFFIC (DDOS) ##################
############### Make sure this Script is executed at Startup! #########
#######################################################################

echo "20000" > /proc/sys/net/ipv4/tcp_max_syn_backlog
echo "1" > /proc/sys/net/ipv4/tcp_synack_retries
echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout
echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes
echo "15" > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo "20000" > /proc/sys/net/core/netdev_max_backlog
echo "20000" > /proc/sys/net/core/somaxconn
echo "99999999" > /proc/sys/net/nf_conntrack_max