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

%end
