# Enterprise Linux 6 (RHEL, CentOS, SL...) TEMPLATE
text
rescue
url --url=http://rpmrepo/mirror/centos/6/os/x86_64/
lang en_US.UTF-8
keyboard us
network --bootproto dhcp
firewall --disabled
timezone --utc America/New_York
