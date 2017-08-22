#!/bin/bash

echo " The script should be RUN after installation using CentOS-7-x86_64-DVD-1503-01.iso"
echo "The script assume that the interfaces you have on your compute node are enp6s0 for management and enp2s0 for provider netwotk"
echo "requireparameters"
PROXY_IP = xx.x.xx.x:xxx
COMPUTE_IP = yy.yy.yy.yy


echo "Backing up the  files"
mkdir -p /backup
cp /etc/profile /backup/profile.bk_`date +%Y.%m.%d.%H.%M.%S`
cp /etc/yum.conf /backup/yum.conf_`date +%Y.%m.%d.%H.%M.%S`
cp /etc/sysconfig/selinux /backup/selinux_`date +%Y.%m.%d.%H.%M.%S`
cp /etc/hosts /backup/hosts_`date +%Y.%m.%d.%H.%M.%S`
cp /etc/resolve.conf /backup/resolve.conf_`date +%Y.%m.%d.%H.%M.%S`

hostname compute2
echo "Updating the profile file"

echo export https_proxy=https://PROXY_IP >> /etc/profile
echo export http_proxy=http://PROXY_IP >> /etc/profile

echo "Updating the yum file"
echo proxy=https://PROXY_IP >> /etc/yum.conf
echo "Updating the Selinux file"
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config && cat /etc/selinux/config

echo "Changing the Provider interface to the boot proto as none"
sed -i 's/^BOOTPROTO=.*/BOOTPROTO=none/g' /etc/sysconfig/network-scripts/ifcfg-enp2s0  && cat /etc/sysconfig/network-scripts/ifcfg-enp2s0

echo "updating the resolve config file, these are the name serevr ips if you have any"

echo "nameserver 10.120.252.54" >> /backup/resolve.txt
echo "nameserver 10.5.25.53" >> /backup/resolve.txt
echo "nameserver 10.239.25.53" >> /backup/resolve.txt

cat /boackup/resolve.txt >> /etc/resolve.conf

echo "updating the hosts files with your set up IP addresses"

echo "10.121.46.32 controller" >> /backup/hosts.txt
echo "10.121.46.34 compute1" >> /backup/hosts.txt
echo "10.121.46.36 compute2" >> /backup/hosts.txt
echo "10.121.46.38 compute3" >> /backup/hosts.txt
echo "10.121.46.48 compute4" >> /backup/hosts.txt
echo "10.121.46.42 compute5" >> /backup/hosts.txt
echo "10.121.46.50 compute6" >> /backup/hosts.txt
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" >> /backup/hosts.txt
echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /backup/hosts.txt
cat /backup/hosts.txt > /etc/hosts

echo "Install the YUM repositories. The folowing are optional but since this is for lab you can install it any way"

yum -y groupinstall "Desktop" "Desktop Platform" "Legacy X Window System Compatibility" "X Window System"
yum -y install tigervnc-server net-tools bind-utils chrony wget

echo "Stop the filrewalls"
systemctl stop firewalld
chkconfig firewalld off

echo "Install the remaining packages"
yum -y install bc.x86_64 binutils.x86_64 compat-libcap1.x86_64
yum -y install compat-libstdc++-33.i686 compat-libstdc++-33.x86_64
yum -y install dbus-glib-devel.i686 elfutils-libelf-devel.x86_64 elfutils.x86_64
yum -y install firefox.x86_64 gcc-c++.x86_64 gcc.x86_64 glibc-devel.i686
yum -y install glibc-devel.x86_64 gtk2.i686 hal-devel.i686 ksh.x86_64
yum -y install libaio-devel.i686 libaio-devel.x86_64 libaio.i686 libaio.x86_64
yum -y install libgcc.x86_64 libibverbs.x86_64 libstdc++-devel libXtst.i686
yum -y install libXtst.x86_64 make.x86_64 numactl-devel.i686 numactl-devel.x86_64
yum -y install openmotif.i686 openssh.x86_64 openssh-askpass.x86_64
yum -y install openssh-clients.x86_64 openssh-server.x86_64 rsync.x86_64
yum -y install sysstat.x86_64 unzip.x86_64 xorg-x11-proto-devel.noarch zip.x86_64
yum –y install libXau.i686 libXau.x86_64 libxcb.i686 libxcb.x86_64
yum -y install qemu-kvm libvirt virt-install bridge-utils

echo "Stop the filrewalls"
systemctl stop firewalld
chkconfig firewalld off


systemctl start libvirtd
systemctl enable libvirtd

echo "installing the OCATA compute packages"

yum install -y centos-release-openstack-ocata
yum -y upgrade
yum --enablerepo=centos-openstack-ocata,epel -y install openstack-nova-compute
yum install -y openstack-nova-compute
yum install -y python-openstackclient
yum install -y openstack-selinux

#echo "password and IP address of controller and management IP needs to be variables"

echo "Backing up the nova.conf file"
cp /etc/nova/nova.conf /backup/nova.conf_`date +%Y.%m.%d.%H.%M.%S`

echo "EDIT the Nova.conf file on the compute node."
sed -i "/^\[DEFAULT\]/a\
enabled_apis = osapi_compute,metadata\n\
transport_url = rabbit://openstack:mainstreet@10.121.46.32\n\
my_ip = COMPUTE_IP\n\
use_neutron = True\n\
firewall_driver = nova.virt.firewall.NoopFirewallDriver"  /etc/nova/nova.conf

sed -i "/^\[api\]/a\
auth_strategy = keystone" /etc/nova/nova.conf


sed -i "/^\[keystone_authtoken\]/a\
auth_uri = http://10.121.46.32:5000\n\
auth_url = http://10.121.46.32:35357\n\
memcached_servers = 10.121.46.32:11211\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
project_name = service\n\
username = nova\n\
password = mainstreet" /etc/nova/nova.conf


sed -i "/^\[vnc\]/a\
enabled = True\n\
vncserver_listen = 0.0.0.0\n\
vncserver_proxyclient_address = 10.121.46.38\n\
novncproxy_base_url = http://10.121.46.32:6080/vnc_auto.html" /etc/nova/nova.conf


sed -i "/^\[glance\]/a\
api_servers = http://10.121.46.32:9292" /etc/nova/nova.conf

sed -i "/^\[oslo_concurrency\]/a\
lock_path = /var/lib/nova/tmp " /etc/nova/nova.conf

sed -i "/^\[placement\]/a\
os_region_name = RegionOne\n\
project_domain_name = Default\n\
project_name = service\n\
auth_type = password\n\
user_domain_name = Default\n\
auth_url = http://10.121.46.32:35357/v3\n\
username = placement\n\
password = mainstreet"  /etc/nova/nova.conf

systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

yum install -y openstack-neutron-linuxbridge ebtables ipset

echo "backing up the neutron.conf"
cp /etc/neutron/neutron.conf /backup/neutron.conf_`date +%Y.%m.%d.%H.%M.%S`

sed -i "/^\[keystone_authtoken\]/a\
auth_uri = http://10.121.46.32:5000\n\
auth_url = http://10.121.46.32:35357\n\
memcached_servers = 10.121.46.32:11211\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
project_name = service\n\
username = neutron\n\
password = mainstreet" /etc/neutron/neutron.conf


sed -i "/^\[DEFAULT\]/a\
transport_url = rabbit://openstack:mainstreet@10.121.46.32\n\
auth_strategy = keystone" /etc/neutron/neutron.conf

sed -i "/^\[oslo_concurrency\]/a\
lock_path = /var/lib/neutron/tmp" /etc/neutron/neutron.conf

echo "backing up the linuxbridge_agent"
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /backup/linuxbridge_agent.ini_`date +%Y.%m.%d.%H.%M.%S`

sed -i "/^\[linux_bridge\]/a\
physical_interface_mappings = provider:enp2s0" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i "/^\[vxlan\]/a\
enable_vxlan = true\n\
local_ip = 10.121.46.38\n\
l2_population = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i "/^\[securitygroup\]/a\
enable_security_group = true\n\
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i "/^\[neutron\]/a\
url = http://10.121.46.32:9696\n\
auth_url = http://10.121.46.32:35357\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
region_name = RegionOne\n\
project_name = service\n\
username = neutron\n\
password = mainstreet" /etc/nova/nova.conf

echo "Restart the Compute service"
systemctl restart openstack-nova-compute.service
systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service
