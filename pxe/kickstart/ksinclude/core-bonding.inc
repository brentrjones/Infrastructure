# Setup physical interfaces for bonding out of the gate

cat << EOF >> /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
ONBOOT=yes
BOOTPROTO="dhcp"
USERCTL=no
NM_CONTROLLED=no
BONDING_OPTS="lacp_rate=fast mode=4 primary=em1"
LINKDELAY=10
EOF

sed -i -e 's/\(^BOOTPROTO=\).*$/\1none/' /etc/sysconfig/network-scripts/ifcfg-em1
sed -i -e 's/\(^ONBOOT=\).*$/\1yes/' /etc/sysconfig/network-scripts/ifcfg-em1
sed -i -e 's/\(^NM_CONTROLLED=\).*$/\1no/' /etc/sysconfig/network-scripts/ifcfg-em1
cat << EOF >> /etc/sysconfig/network-scripts/ifcfg-em1
MASTER=bond0
SLAVE=yes
LINKDELAY=10
EOF

sed -i -e 's/\(^BOOTPROTO=\).*$/\1none/' /etc/sysconfig/network-scripts/ifcfg-em2
sed -i -e 's/\(^ONBOOT=\).*$/\1yes/' /etc/sysconfig/network-scripts/ifcfg-em2
sed -i -e 's/\(^NM_CONTROLLED=\).*$/\1no/' /etc/sysconfig/network-scripts/ifcfg-em2
cat << EOF >> /etc/sysconfig/network-scripts/ifcfg-em2
MASTER=bond0
SLAVE=yes
LINKDELAY=10
EOF
