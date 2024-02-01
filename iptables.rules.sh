#!/bin/sh


####################################################
############# Customize Stuff HERE #################
####################################################


#### Your default SSH and FTP ports
SSH_PORT="21:23"

#### Your GameServer Ports
GAMESERVERPORTS="27015:27016"

#### Tickrate you run Servers on (to determine actual maximum cmdrate)
CMD_LIMIT=100

#### Whitelisted IPs (For rcon and other traffic from trusted sources)
#### Add a space between IP addresses. (ie. WHITELISTEd_IPS="1.2.3.4 127.0.0.1 10.0.0.1")
WHITELISTED_IPS=""


####################################################
############### Do not modify~! ####################
####################################################
CMD_LIMIT_LEEWAY=$(($CMD_LIMIT + 10))
CMD_LIMIT_UPPER=$(($CMD_LIMIT + 30))


###################################################################################################################
# _|___|___|___|___|___|___|___|___|___|___|___|___|                                                             ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__        IPTables: Linux's Main line of Defense               ##
# _|___|___|___|___|___|___|___|___|___|___|___|___|        IPTables: Linux's way of saying no to DoS kids       ##
# ___|___|___|___|___|___|___|___|___|___|___|___|__                                                             ##
# _|___|___|___|___|___|___|___|___|___|___|___|___|        Version 2.0   -                                      ##
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


## Create Chains
##---------------------
iptables -N UDP_GAME_NEW_LIMIT
iptables -N UDP_GAME_NEW_LIMIT_GLOBAL
iptables -N UDP_GAME_ESTABLISHED_LIMIT
iptables -N A2S_LIMITS
iptables -N A2S_PLAYERS_LIMITS
iptables -N A2S_RULES_LIMITS
iptables -N STEAM_GROUP_LIMITS
##---------------------


## Create Rules
##---------------------
iptables -A UDP_GAME_NEW_LIMIT -m hashlimit --hashlimit-upto 1/s --hashlimit-burst 3 --hashlimit-mode srcip,dstport --hashlimit-name L4D2_NEW_HASHLIMIT --hashlimit-htable-expire 5000 -j UDP_GAME_NEW_LIMIT_GLOBAL
iptables -A UDP_GAME_NEW_LIMIT -j DROP
iptables -A UDP_GAME_NEW_LIMIT_GLOBAL -m hashlimit --hashlimit-upto 10/s --hashlimit-burst 20 --hashlimit-mode dstport --hashlimit-name L4D2_NEW_HASHLIMIT_GLOBAL --hashlimit-htable-expire 5000 -j ACCEPT
iptables -A UDP_GAME_NEW_LIMIT_GLOBAL -j DROP
iptables -A UDP_GAME_ESTABLISHED_LIMIT -m hashlimit --hashlimit-upto ${CMD_LIMIT_LEEWAY}/s --hashlimit-burst ${CMD_LIMIT_UPPER} --hashlimit-mode srcip,srcport,dstport --hashlimit-name L4D2_ESTABLISHED_HASHLIMIT -j ACCEPT
iptables -A UDP_GAME_ESTABLISHED_LIMIT -j DROP
iptables -A A2S_LIMITS -m hashlimit --hashlimit-upto 8/sec --hashlimit-burst 30 --hashlimit-mode dstport --hashlimit-name A2SFilter --hashlimit-htable-expire 5000 -j ACCEPT
iptables -A A2S_LIMITS -j DROP
iptables -A A2S_PLAYERS_LIMITS -m hashlimit --hashlimit-upto 8/sec --hashlimit-burst 30 --hashlimit-mode dstport --hashlimit-name A2SPlayersFilter --hashlimit-htable-expire 5000 -j ACCEPT
iptables -A A2S_PLAYERS_LIMITS -j DROP
iptables -A A2S_RULES_LIMITS -m hashlimit --hashlimit-upto 8/sec --hashlimit-burst 30 --hashlimit-mode dstport --hashlimit-name A2SRulesFilter --hashlimit-htable-expire 5000 -j ACCEPT
iptables -A A2S_RULES_LIMITS -j DROP
iptables -A STEAM_GROUP_LIMITS -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 3 --hashlimit-mode srcip,dstport --hashlimit-name STEAMGROUPFilter --hashlimit-htable-expire 5000 -j ACCEPT
iptables -A STEAM_GROUP_LIMITS -j DROP

#### Allow Self
iptables -A INPUT -i lo -j ACCEPT

#### Allow traffic to Gameservers from Whitelisted IPs
for ip in $WHITELISTED_IPS; do
    iptables -A INPUT -p tcp -m multiport --dports $GAMESERVERPORTS -s $ip -j ACCEPT
	iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -s $ip -j ACCEPT
done

#### These lengths will never be used for valid packets.
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 0:28 -j DROP
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m length --length 2521:65535 -j DROP

#### A2S & Steam Group Server Queries
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m string --algo bm --hex-string '|FFFFFFFF54|' -j A2S_LIMITS
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m string --algo bm --hex-string '|FFFFFFFF55|' -j A2S_PLAYERS_LIMITS
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m string --algo bm --hex-string '|FFFFFFFF56|' -j A2S_RULES_LIMITS
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m string --algo bm --hex-string '|FFFFFFFF00|' -j STEAM_GROUP_LIMITS

#### Rate-limit NEW UDP Connections.
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m state --state NEW -j UDP_GAME_NEW_LIMIT

#### Rate-limit ESTABLISHED UDP Connections.
iptables -A INPUT -p udp -m multiport --dports $GAMESERVERPORTS -m state --state ESTABLISHED -j UDP_GAME_ESTABLISHED_LIMIT

#### Accept Established Connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#### SSH && ICMP.
iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m hashlimit --hashlimit-upto 2/sec --hashlimit-burst 5 --hashlimit-mode dstport --hashlimit-name SSHPROTECT -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 10/s -j ACCEPT

## Drop everything else!
##--------------------
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP
iptables -A OUTPUT -j ACCEPT
##--------------------