#!/bin/sh

# Init environment variables from DTK
echo "Loading environment"
cd /opt/dell/toolkit/template/scripts
./tkenvset.sh
export PATH=/sbin:/usr/sbin:/bin:/usr/bin:/opt/dell/toolkit/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/opt/dell/toolkit/template/scripts

# RAID erase? Set local variable to control if RAID set is wiped and started fresh
# This is useful if you want to provision the BIOS, without wiping RAID and all data out
raiderase=0

echo "Setting up BIOS/RAID"

export temppath=/tmp/templates
export biosfile=620-bios.ini
export raidfile=620-raid.ini
export idracfile=620-idrac.ini

export svctag=`syscfg --svctag| awk -F= '{print $2}' `
export logpath=/tmp
export logfile=$svctag.txt

mkdir -p /tmp/templates/

echo "Downloading BIOS config from repo"
wget http://rpmrepo.domain/tftpboot/el6/dtk/templates/620-bios.ini -O $temppath/$biosfile
if [ $? != 0 ]; then
        echo Wget Failed
fi

echo "Downloading RAID config from repo"
wget http://rpmrepo.domain/tftpboot/el6/dtk/templates/620-raid.ini -O $temppath/$raidfile
if [ $? != 0 ]; then
        echo Wget Failed
fi

echo "Downloading iDRAC config from repo"
wget http://rpmrepo.domain/tftpboot/el6/dtk/templates/620-idrac.ini -O $temppath/$idracfile
if [ $? != 0 ]; then
        echo Wget Failed
fi

sysrep () {
    if [ ! -e $temppath/$biosfile ] ; then
        echo "$biosfile : File specified does not exist." >> $logpath/$logfile
    else sh sysrep.sh $temppath/$biosfile $logpath/$logfile
    if [ $? != 0 ]; then
        sleep 10 ; sysrep
        else raidrep
    fi
    fi
}


raidrep () {
    if [ "$raiderase" -eq "1" ] ; then
        if [ ! -e $temppath/$raidfile ] ; then
            echo "$raidfile : File specified does not exist." >> $logpath/$logfile
        else sh raidrep.sh $temppath/$raidfile $logpath/$logfile
            if [ $? != 0 ]; then
              raidrep
            else racrep
            fi
        fi
    else racrep
    fi
}

racrep () {
    if [ ! -e $temppath/$idracfile ] ; then
        echo "$idracfile : File specified does not exist." >> $logpath/$logfile
    else sh racrep.sh $temppath/$idracfile $logpath/$logfile
    fi
}

sysrep

#echo ""
#echo "Uploading transaction logs"
#echo "tftp -p -l $logpath/$logfile -r el6/dtk/logs/$logfile $tftp_ip"
#tftp -p -l $logpath/$logfile -r el6/dtk/logs/$logfile $tftp_ip
#if [ $? != 0 ]; then
#        echo TFTP FILE TRANSFER $share_script FAILED
#fi

sleep 5; reboot

exit $retsyscfg
