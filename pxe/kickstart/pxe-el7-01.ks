install
text
reboot
url --url=http://rpmrepo/mirror/centos/7/os/x86_64/
lang en_US.UTF-8
keyboard us
network --onboot=on --bootproto dhcp
rootpw somehash
firewall --disabled --service=ssh
authconfig --enableshadow --enablemd5
timezone --utc America/New_York

# Disk part and boot loader
%include http://rpmrepo/kickstart/ksinclude/part-el7-generic

# Initial install repos
%include http://rpmrepo/kickstart/ksinclude/pre-el7-repo-internal

# Package selecting
%packages --nobase
%include http://rpmrepo/kickstart/ksinclude/packages-el7-generic
%end

%pre


%end

%post

# log post-install and switch to tty7
exec >/root/post-install.log 2>&1
tail -f /root/post-install.log >/dev/tty7 &
/usr/bin/chvt 7

%include http://rpmrepo/kickstart/ksinclude/post-el7-core

# Uncomment to setup physical interfaces for bonding out of the gate
# Change eth device name to match local

#cat << EOF >> /etc/sysconfig/network-scripts/ifcfg-bond0
#DEVICE=bond0
#ONBOOT=yes
#BOOTPROTO="dhcp"
#USERCTL=no
#NM_CONTROLLED=no
#BONDING_OPTS="lacp_rate=fast mode=4 primary=em1"
#LINKDELAY=10
#EOF

#sed -i -e 's/\(^BOOTPROTO=\).*$/\1none/' /etc/sysconfig/network-scripts/ifcfg-em1
#sed -i -e 's/\(^ONBOOT=\).*$/\1yes/' /etc/sysconfig/network-scripts/ifcfg-em1
#sed -i -e 's/\(^NM_CONTROLLED=\).*$/\1no/' /etc/sysconfig/network-scripts/ifcfg-em1
#cat << EOF >> /etc/sysconfig/network-scripts/ifcfg-em1
#MASTER=bond0
#SLAVE=yes
#LINKDELAY=10
#EOF

#sed -i -e 's/\(^BOOTPROTO=\).*$/\1none/' /etc/sysconfig/network-scripts/ifcfg-em2
#sed -i -e 's/\(^ONBOOT=\).*$/\1yes/' /etc/sysconfig/network-scripts/ifcfg-em2
#sed -i -e 's/\(^NM_CONTROLLED=\).*$/\1no/' /etc/sysconfig/network-scripts/ifcfg-em2
#cat << EOF >> /etc/sysconfig/network-scripts/ifcfg-em2
#MASTER=bond0
#SLAVE=yes
#LINKDELAY=10
#EOF

%end
