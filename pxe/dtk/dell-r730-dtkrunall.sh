#!/bin/bash

# Init environment variables from DTK
echo -e "\e[32mLoading environment variables\e[0m"
sleep 2
cd /opt/dell/toolkit/template/scripts
./tkenvset.sh

export PATH=/sbin:/usr/sbin:/bin:/usr/bin:/opt/dell/toolkit/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/opt/dell/toolkit/template/scripts
export temppath=/tmp/templates
export biosfile=dell-r730-bios.ini
export raidfile=dell-r730-raid.ini
export idracfile=dell-r730-idrac.ini
export dtkxml=dell-r730-clone.xml
export svctag=`syscfg --svctag| awk -F= '{print $2}' `
export logpath=/tmp
export logfile=$svctag.txt

mkdir -p /tmp/templates/


echo -e "\e[32mDownloading BIOS config from repo\e[0m"
wget -q http://rpmrepo/tftpboot/el6/dtk/templates/dell-r730-bios.ini -O $temppath/$biosfile
sleep 2
if [ $? != 0 ]; then
    echo -e "\e[31mWget Failed\e[0m"
    exit 1
fi


echo -e "\e[32mDownloading RAID config from repo\e[0m"
sleep 2
wget -q http://rpmrepo/tftpboot/el6/dtk/templates/dell-r730-raid.ini -O $temppath/$raidfile
if [ $? != 0 ]; then
    echo -e "\e[31mWget Failed\e[0m"
    exit 1
fi


echo -e "\e[32mDownloading iDRAC config from repo\e[0m"
sleep 2
wget -q http://rpmrepo/tftpboot/el6/dtk/templates/dell-r730-idrac.ini -O $temppath/$idracfile
if [ $? != 0 ]; then
    echo -e "\e[31mWget Failed\e[0m"
    exit 1
fi


echo -e "\e[32mDownloading racadm XML config from repo\e[0m"
wget -q http://rpmrepo/tftpboot/el6/dtk/templates/dell-r730-clone.xml -O $temppath/$dtkxml
sleep 2
if [ $? != 0 ]; then
    echo -e "\e[31mWget Failed\e[0m"
    exit 1
fi


raidrep () {
    echo -e "\e[32mImporting RAID configuration . . .\e[0m"
    sleep 2
    if [ ! -e $temppath/$raidfile ] ; then
        echo -e "\e[31m$raidfile : File specified does not exist.\e[39m" >> $logpath/$logfile
    else sh raidrep.sh $temppath/$raidfile $logpath/$logfile
        if [ $? != 0 ]; then
            echo -e "\e[31mSomething Failed.\e[0m"
            exit 1
        else
            sysrep
        fi
    fi
}


sysrep () {
    echo -e "\e[32mImporting racadm XML\e[0m"
    sleep 2
    if [ ! -e $temppath/$dtkxml ] ; then
        echo -e "\e[31m$biosfile : File specified does not exist.\e[0m" >> $logpath/$logfile
    else
        echo -e "\e[41;5mDO NOT TOUCH SYSTEM\nDO NOT TOUCH SYSTEM\nDO NOT TOUCH SYSTEM\n\nSystem will automatically restart to resume configuration\e[0m"
        sleep 15
        racadm set -f $temppath/$dtkxml -t xml -b NoReboot -s On
        if [ $? != 0 ]; then
            echo -e "\e[31mSomething Failed. Get help...\e[0mm"
        else
            finish
        fi
    fi
}


upload_logs () {
    echo ""
    echo "Uploading transaction logs"
    echo "tftp -p -l $logpath/$logfile -r el6/dtk/logs/$logfile $tftp_ip"
    tftp -p -l $logpath/$logfile -r el6/dtk/logs/$logfile $tftp_ip
    if [ $? != 0 ]; then
        echo TFTP FILE TRANSFER $share_script FAILED
        finish
    else
        finish
    fi
}


finish () {
    echo -e "\e[32mEverything should be good to go . . .\e[0m"
    sleep 3
    echo -e "\e[41;5mSystem POWERING OFF\n"
    echo -e "DO NOT TOUCH SYSTEM\nDO NOT TOUCH SYSTEM\nDO NOT TOUCH SYSTEM\n\nSystem will automatically restart to resume configuration\e[0m"
    sleep 15
    reboot
}


# Main
raidrep
