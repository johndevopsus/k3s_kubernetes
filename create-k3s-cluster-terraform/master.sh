#! /bin/bash
apt-get update -y
apt-get upgrade -y
hostnamectl set-hostname k3s-master
chmod 777 /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
chmod 644 /etc/sysctl.conf
curl -sfL https://get.k3s.io | sh -
systemctl status k3s.service

