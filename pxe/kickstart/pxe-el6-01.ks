# Enterprise Linux 6 (RHEL, CentOS, SL...) TEMPLATE
install
text
reboot
url --url=http://rpmrepo/mirror/centos/6/os/x86_64/
key --skip
lang en_US.UTF-8
keyboard us
network --onboot=on --bootproto dhcp
rootpw somehash
firewall --disabled
authconfig --enableshadow --enablemd5
timezone --utc America/New_York

# Initial install repos
%include http://rpmrepo/kickstart/ksinclude/pre-repo-internal

# Package selecting
%packages --nobase
%include http://rpmrepo/kickstart/ksinclude/packages-el6-generic

%pre

%include http://rpmrepo/kickstart/ksinclude/part-el6-generic

%post

# log post-install and switch to tty7
exec >/root/post-install.log 2>&1
tail -f /root/post-install.log >/dev/tty7 &
/usr/bin/chvt 7

%include http://rpmrepo/kickstart/ksinclude/post-el6-core
