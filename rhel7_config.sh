#!/bin/bash
# version 1.0
# Last modified on 09/19/2018 Dawit Gebru Epicor Software
# Configure RHEL 7 for Eclipse Environment
# prerequisites: RHEL subscription, Volumegroup

LOGFILE=/esupport/rhel7_config.log
TIMESTAMP=`date +%Y%m%d.%H%M%S`
VOLUMEGROUP=datavg
BAR='--------------------------------------------------------------------------------'

exec >> $LOGFILE
exec 2>&1

# setup Eclipse Environment
config_base_os () {

echo "Set the history command to display time stamp"
echo -e "\n# Display time stamp for history commands\nexport HISTTIMEFORMAT='%F %T '" >> /etc/profile

echo "Hide the tmpfs filesystems from 'df' command"
wget -P /etc/profile.d/ ftp://eclsys:Epicor2011\!@ftp.activant.com/linux/utils/df2.sh

echo $BAR
echo "Enable Network Time Protocol"
timedatectl set-ntp yes

}

# Install groups & packages for Eclips
install_req_packages () {
echo $BAR
echo "Install utilities used by Eclipse/UniVerse"
yum -y groupinstall base core print-client
yum -y install ksh dos2unix ftp
yum -y install compat-libstdc++-33-3.2.3-71.el7.i686

}

# Skip this step for CentOS7
config_repos () {

echo $BAR
echo "Enable the 'optional' and 'extras' repositories to use EPEL packages "

subscription-manager repos --enable=rhel-7-server-optional-rpms
subscription-manager repos --enable=rhel-7-server-extras-rpms
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

}

# Install munin for monitoring system resources
config_munin () {

echo $BAR
echo "Install Apache and munin"
yum install httpd -y
systemctl enable httpd
systemctl start httpd

yum -y install munin munin-node
systemctl enable munin-node
systemctl start munin-node

echo "Disable Munin password Protection"
sed -i 's/AuthUserFile/#AuthUserFile/g' /etc/httpd/conf.d/munin.conf
sed -i 's/AuthName/#AuthName/g' /etc/httpd/conf.d/munin.conf
sed -i 's/AuthType/#AuthType/g' /etc/httpd/conf.d/munin.conf
sed -i 's/require valid-user/#require valid-user/g' /etc/httpd/conf.d/munin.conf

}

# Install and configure telnet for ETERM & CTERM users
config_telnet () {
echo "Install telnet-server"
yum -y install telnet telnet-server
systemctl start telnet.socket
systemctl enable telnet.socket

echo "Increase the telent connection limit to 1k"
mkdir /etc/systemd/system/telnet.socket.d
echo -e "[Socket]\nMaxConnections=1024" >/etc/systemd/system/telnet.socket.d/MaxCon.conf
systemctl daemon-reload

}

# Install and configure samba for document imaging
#
config_samba () {

echo $BAR
echo "Install samba:"
yum -y install samba-client samba-winbind samba


echo "Enable samba services:"

systemctl enable smb.service
systemctl enable nmb.service
systemctl enable winbind.service
systemctl restart smb.service
systemctl restart nmb.service
systemctl restart winbind.service

echo "Install Eclipse samba configuration file:"

mv /etc/samba/smb.conf /etc/samba/smb.conf.`date +%Y%m%d.%H%M%S`
wget -P /etc/samba/ ftp://eclsys:Epicor2011\!@ftp.activant.com/linux/scripts/smb.conf

}

#
# Configure CUPS printing subsystem 
config_cups () {

echo $BAR
echo "CUPS: update log size and job history "
cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.`date +%Y%m%d.%H%M%S`
cupsctl MaxLogSize=100m
cupsctl PreserveJobHistory=No
systemctl restart cups

}


# Skip VNC install if not an ABS customer
# prerequisites: the ecladmin account 
config_vnc () {
echo $BAR
echo "Install vncserver"

yum -y groupinstall "GNOME"
yum -y install tigervnc-server

echo "Enable VNC for ecladmin account"
cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:1.service
sed -i 's/^ExecStart=\/usr\/sbin\/runuser -l <USER>/ExecStart=\/usr\/sbin\/runuser -l ecladmin/g' /etc/systemd/system/vncserver@:1.service
sed -i 's/^PIDFile=\/home\/<USER>/PIDFile=\/home\/ecladmin/g' /etc/systemd/system/vncserver@:1.service
systemctl daemon-reload

echo "set a temp ecladmin vnc password"

su - ecladmin
echo abc123 >/tmp/file
echo abc123 >>/tmp/file
vncpasswd </tmp/file >/tmp/vncpasswd.1 2>/tmp/vncpasswd.2
exit
systemctl enable vncserver@:1.service
systemctl start vncserver@:1.service
echo $BAR

}

# Disable firewall rules
#To do: intstall firewall rules 
disable_firewall () {

echo "Firewall: Disabled"
systemctl disable firewalld
systemctl stop firewalld

}
# UniVerse telnet services will not work if SELINUX is enabled
# To do: 
disable_selinux () {

echo $BAR
echo "Disable SELinux"

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive /g' /etc/selinux/config


}

#
#Disable virtual interface

disable_virbr0 () {
echo $BAR
echo "Disable virbr0"

virsh net-destroy default
virsh net-autostart default --disable
virsh net-undefine default
systemctl disable libvirtd.service

}

#
# Disable avahi 
disable_avahi () {
echo $BAR
echo "Disable avahi"

systemctl stop avahi-daemon.socket
systemctl stop avahi-daemon.service
systemctl disable avahi-daemon.socket
systemctl disable avahi-daemon.service

}

# Configuer the Eclipse file systems
config_storage () {

echo $BAR
echo "Storage configuration:"

cp /etc/fstab /etc/fstab.$TIMESTAMP
echo "/dev/$VOLUMEGROUP/u2          /u2                     xfs     defaults          1 2 " >> /etc/fstab
echo "/dev/$VOLUMEGROUP/eclipse     /u2/eclipse             xfs     defaults          1 2 " >> /etc/fstab
echo "/dev/$VOLUMEGROUP/uvtmp       /u2/uvtmp               xfs     defaults          1 2 " >> /etc/fstab
echo "/dev/$VOLUMEGROUP/ereports    /u2/eclipse/ereports    xfs     defaults          1 2 " >> /etc/fstab


lvcreate -L 4G $VOLUMEGROUP -n u2
mkfs -t xfs -L u2 /dev/$VOLUMEGROUP/u2
mkdir -p /u2
mount /u2

lvcreate -L 40G $VOLUMEGROUP -n eclipse
mkfs -t xfs -L eclipse /dev/$VOLUMEGROUP/eclipse
mkdir -p /u2/eclipse
mount /u2/eclipse

lvcreate -L 4G $VOLUMEGROUP -n ereports
mkfs -t xfs -L ereports /dev/$VOLUMEGROUP/ereports
mkdir -p /u2/eclipse/ereports
mount /u2/eclipse/ereports

lvcreate -L 4G $VOLUMEGROUP -n uvtmp
mkfs -t xfs -L uvtmp /dev/$VOLUMEGROUP/uvtmp
mkdir -p /u2/uvtmp
mount /u2/uvtmp
chmod 1777 /u2/uvtmp

mkdir -p /u2/exports
chmod 777 /u2/exports

}

install_updates () {
echo $BAR
echo "Install RHEL updates:"
yum -y update
}

config_compete () {

echo "OS config complete... "
exit 0
}
#This is where the Scripts starts:

config_base_os
install_req_packages
config_repos
disable_selinux
disable_virbro
disable_avahi
disable_firewall
config_cups
config_telnet
config_samba
config_munin
config_vnc
config_storage
install_updats
config_compete



