#!/bin/ksh -p
# ZFS snapshot replication script
# Sections borrowed from:
# http://blogs.sun.com/constantin/entry/zfs_replicator_script_new_edition
# 
# Modified and changed to meet my own needs
# Brent Jones
# http://www.brentrjones.com
# brent@brentrjones.com
#

# Grab commandline argument variables
sourcefs=$1
destfsroot=$2
RHOST=$3

# Create a dest fs variable derived from source fs
destfs=$destfsroot/`echo $sourcefs | cut -d/ -f2,3-`

# Establish a ZFS user property to store replication settings/locking
# This ensures multiple snapshots/replication won't occur on the same file system
# Also adds a "dependency" field, so you don't accidently delete a snapshot that is still
# required to compare incremental sends.
repllock="replication:locked"
replconfirmed="replication:confirmed"
repldepend="replication:depend"

# Contact e-mail address
contact="youremail@host.com"

# Get a good date format from 'date' YYYYMMDD-HH:MM:SS
snap=`date +%Y%m%d-%H:%M:%S`

# Define local and remote ZFS commands and SSH param
LZFS="/sbin/zfs"
RZFS="ssh -c blowfish $RHOST /sbin/zfs"

# Usage info
usage() {
cat <<EOT
usage: replicate.ksh [local filesystem] [remote target pool] [remote host address]
        eg. replicate.ksh tank remotetank 192.168.1.1
EOT
}

if [ $# -lt 3 ]; then
  usage
  exit 1
fi

# Check the local and remote filesystems for locks from other jobs so we don't run multiples
localfslocked=`$LZFS get -H $repllock $sourcefs | cut -f3`
remotefslocked=`$RZFS get -H $repllock $destfs | cut -f3`

if [[ $localfslocked = "true" || $remotefslocked = "true" ]];then
    echo "\nFilesystem locked, quitting: $sourcefs"
    echo "\nFilesystem locked" \
    "\n$sourcefs is locked: $localfslocked" \
    "\n$destfs is locked: $remotefslocked" \
    | mailx -s "Failed snapshot: $sourcefs" $contact;
    exit 1;
  else
    $LZFS set $repllock=true $sourcefs
fi

# Get the most recent snapshot from localhost
localprevsnap=`$LZFS list -Hr -o name -s creation -t snapshot $sourcefs | tail -1`

# Get the same variable and strip the root poolname out so we can work with it to compare later
remoteprevsnap=`$LZFS list -Hr -o name -s creation -t snapshot $sourcefs | tail -1 | cut -d/ -f2,3-`

# Variable to give new snapshot name eg. tank@20090211-12:30:10 and give it a remote prefix
newsnap="$sourcefs@$snap"
remotenewsnap=$destfsroot/`echo $newsnap | cut -d/ -f2,3-`


# If the remote most recent snapshot doesnt match ours, give up
# However if it does, attempt to send an incremental snapshot
# from the last recent local snapshot, with the one just taken above

if [ -z "`$RZFS list -Ho name -s creation -t snapshot | grep $destfsroot/$remoteprevsnap`" ]; then
    echo "The Source snapshot doesn't exist on the Destination, manual intervention required!"\
         "\nSource: $localprevsnap $newsnap"\
         "\nDestination: $RHOST - $destfsroot" \
         | mailx -s "Failed snapshot: $newsnap" $contact;
  else
    echo "The Source snapshot does exist on the Destination, clear to send a new one!"
    echo "Taking snapshot: $LZFS snapshot $newsnap"
    # Take the snapshot now
    $LZFS snapshot $newsnap
    $LZFS send -i $localprevsnap $newsnap | $RZFS recv -vFd $destfsroot || \
      {
        echo "Error when zfs send/receiving. Destroying $newsnap";
        $LZFS destroy $newsnap;
        echo "Failed snapshot replication" \
        "\nSource: $localprevsnap $newsnap" \
        "\nDestination: $RHOST - $destfsroot" \
        "\nDestroyed new snapshot: $newsnap" \
        | mailx -s "Failed snapshot: $newsnap" $contact;
        $LZFS set $repllock=false $sourcefs
        exit 1;
      }
    $LZFS set $repllock=false $sourcefs
    $LZFS set $replconfirmed=true $newsnap
    $LZFS set $repldepend=false $localprevsnap
    $LZFS set $repldepend=true $newsnap
    $RZFS set $repllock=false $destfs
    $RZFS set $replconfirmed=true $remotenewsnap
    $RZFS set $repldepend=false $destfsroot/$remoteprevsnap
    $RZFS set $repldepend=true $remotenewsnap
fi