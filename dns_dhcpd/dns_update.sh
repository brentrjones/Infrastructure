#!/bin/bash

# Functions to perform dynamic DNS updates to an authoratative nameserver.
# We collect local information: Interface, IP address, determine which
# cloud platform we find ourselves on. In which case, we look for a
# config-drive or meta-data service to find out who we are.
# We then build an 'nsupdate' command to publish that information to
# an authoratative nameserver (automatically determined from TLD and PTR)
# 
# This could be expanded to support Route53 or Dynect as needed.
# 
# Happy systems / bjones


get_active_int ()
{
    int=`route | grep '^default' | grep -o '[^ ]*$'`
    # Below section not used - Ubuntu turns out to choose pretty random names for virtual NICs :O
    # Known distributions use systemd/udev rules to choose consistent interface names nowdays.
    # We see ens192 and eth0 most often on VMs. Physical hardware will see <pci-bus-id> but we don't care.
    #ifconfig eth0 >/dev/null 2>&1
    #if [ $? -eq 0 ]; then
    #   int="eth0"
    #else
    #    ifconfig ens192 >/dev/null 2>&1
    #    if [ $? -eq 0 ]; then
    #        int="ens192"
    #    fi
    #fi
    echo "Active Int: $int"
    get_ip
}

get_ip ()
{
    # Find us the IP from the interface and build a string for the PTR zone update
    get_ip="$(/sbin/ip -o -4 addr list $int | awk '{print $4}' | cut -d/ -f1)"
    if [ $? -eq 0 ]; then
        ip=$get_ip
        arpa=$(printf %s "$ip." | tac -s.)in-addr.arpa
        echo "Active IP: $ip"
        echo $arpa
    fi
    determine_cloud
}

determine_cloud ()
{
    # Config drive (Openstack, oVirt)
    # Meta-data server (Neutron-enabled Openstack, AWS, Rackspace)
    drive="/dev/disk/by-label/config-2"
    if [ -e "$drive" ]; then
        config_drive
    else
        meta_data
    fi
}

config_drive ()
{
    # Attempt config drive first. Some clouds drop us an ISO9660 to mount. Does NOT allow dynamic meta-data.
    # Find the drive by label - it works.
    drive="/dev/disk/by-label/config-2"
    mount $drive /media
    get_hostname="$(cat /media/openstack/latest/meta_data.json | python -c "import json,sys;obj=json.load(sys.stdin);print obj['hostname'];")"
    if [ $? -eq 0 ]; then
        hostname=$get_hostname
        echo $hostname
    fi
    assemble_update
}

meta_data ()
{
    # Use meta-data service when live
    user_data_url="http://169.254.169.254/latest/user-data"
    meta_data_url="http://169.254.169.254/latest/meta-data/hostname"
    # Try to find user-data FQDN first, if not, use the private DNS hostname from meta-data provider
    user_data_hostname="$(curl -s $user_data_url | grep fqdn)"
    if [ $? -eq 0 ]; then
        user_method="$(curl -s $user_data_url | grep fqdn | cut -f2 -d' ')"
        hostname=$user_method
        echo $hostname
    else
        meta_data_hostname="$(curl -s $meta_data_url)"
        hostname=$meta_data_hostname
        echo $hostname
    fi
    assemble_update
}

assemble_update ()
{
    # Build the nsupdate commands and stash them in a temp file
    cat > /tmp/up.cmd << EOF
update delete $hostname. A
update add $hostname 60 A $ip
send
update delete $arpa
update add $arpa 60 PTR $hostname.
send
EOF

exec_update
}

exec_update ()
{
nsupdate -d /tmp/up.cmd
if [ $? -eq 0 ]; then
    echo "DNS Update succeeded"
else
    echo "DNS Update Failed"
fi
}

get_active_int
