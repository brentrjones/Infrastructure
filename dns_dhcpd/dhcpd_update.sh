#!/bin/bash
# Vars
errorsto="admin@domain.com"
error_out="/home/svn-dhcp/error.out"
rand=$((RANDOM%10))
fqdn=`hostname -f`
hostname=`hostname -s`

# Reset error log file
echo /dev/null > $error_out


md5_orig ()
{
    orig_md5=`find /etc/dhcp/ -type f -regex ".*\(.conf\|.leases\)" -exec md5sum {} \; | cut -f1 -d' '`
    #orig_md5=`md5sum /etc/dhcp/* | cut -f1 -d' '`
    echo "Old MD5: $orig_md5"
    svn_up
}


md5_new ()
{
    new_md5=`find /etc/dhcp/ -type f -regex ".*\(.conf\|.leases\)" -exec md5sum {} \; | cut -f1 -d' '`
    #new_md5=`md5sum /etc/dhcp/* | cut -f1 -d' '`
    echo "New MD5: $new_md5"
    eval_md5
}


eval_md5 ()
{
    if [ "$orig_md5" != "$new_md5" ]; then
        echo "MD5 changed - testing config..."
        test_config
    else
        echo "Same MD5, exiting..."
        exit 0
    fi
}


svn_up ()
{
    output=`/bin/svn up /etc/dhcp 2>&1`
    if [ $? -eq 0 ]; then
        echo "SVN completed"
    else
        result="`hostname -f` - SVN update error\n\n"
        echo -ne $result >> $error_out
        echo -e "$output" >> $error_out
        reporterror
    fi
    md5_new
}


test_config ()
{
    output=`/sbin/dhcpd -t -cf /etc/dhcp/dhcpd.conf 2>&1`
    if [ $? -eq 0 ]; then
        echo "DHCP syntax check successful"
        dhcp_restart
    else
    result="`hostname -f` - DHCP config syntax error\n\n"
        svn_log=`/bin/svn log -r COMMITTED`
        echo -e "$svn_log" >> $error_out
        echo -ne $result >> $error_out
        echo -e "$output" >> $error_out
        reporterror
    fi
}


dhcp_restart ()
{
    output=`/bin/sudo /bin/systemctl restart dhcpd`
    if [ $? -eq 0 ]; then
        echo "DHCP restarted"
    else
        result="`hostname -f` - DHCP could not be restarted\n\n"
        echo -ne $result >> $error_out
        echo -e "$output" >> $error_out
        reporterror
    fi
}


reporterror ()
{
  mail -s "DHCPd Config Error" $errorsto < $error_out
  exit 1
}


# Start main
md5_orig