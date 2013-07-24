**Setup**
=========

1. Edit the Script in Notepad and customize it to your liking, everything is explained.
2. Upload the Script to a anywhere the root/sudo can access. (/etc would be the best folder)
3. Make sure the file is executable, run "chmod +x /locationofthefile/iptables.rules.sh
4. Run the Script. (/locationofthefile/iptables.rules.sh)
5. Run the following command: iptables-save > /etc/iptables.up.rules
6. You will have to make sure the IPTables are set at System Reboot.

*This step will depend on your Linux Distro*

**Debian**

1. Enter the command; nano /etc/network/if-pre-up.d/iptables
2. Add the following lines to it and make the file executable.

#######!/bin/bash
######/sbin/iptables-restore < /etc/iptables.up.rules

Make the file executable by using; chmod +x /etc/network/if-pre-up.d/iptables

**Ubuntu**

1. Enter the command; nano /etc/network/interfaces
2. Add a single line (shown below) just after ‘iface lo inet loopback’:

pre-up iptables-restore < /etc/iptables.up.rules

**Other Distros**

I'm afraid I can't help you here, you'll have to google your way out of this one!

**FAQ/Issues**
=============

Please make sure you've followed the instructions first!
If you're 100% certain that you have, here's a few questions I expect.

**Errors**
--------------

- *-bash: /filelocationhere/iptables.rules.sh: /bin/sh^M: bad interpreter: No such file or direct*

The file was saved in a DOS Format, it needs to be Unix.

1. vi /filelocationhere/iptables.rules.sh
2. Press Shift + :
3. Write: %s/^M//g (To get the ^M, Hold Ctrl while pressing V and M
4. Press Shift + :
5. Write: wq

- *bash: /filelocationhere/iptables.rules.sh: Permission denied*

Ahah, gotcha!
You didn't follow the instructions fully.

chmod +x /filelocationhere/iptables.rules.sh

**FAQ**
----------

- *Is it safe to make changes?*

Yes, you can safely make changes.
When you're done, execute the script and then do "iptables-save > /etc/iptables.up.rules"

- *Where do the Logs get saved?*

You can view the logs in: /var/logs/messages
Easiest way to find Invalid Packets/Flood is to search for either;

Invalid Packets Dropped:
Valid Packets (Flood) Dropped:

* SRC= The source ip-address from where the packet originated
* DST= The destination ip-address where the packet was sent to
* LEN= Length of the packet
* PROTO= Indicates the protocol. (UDP in this case)
* SPT= Indicates the source port.
* DPT= Indicates the destination port.




