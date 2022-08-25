#! /bin/bash
apt-get update -y
apt-get upgrade -y
hostnamectl set-hostname k3s-worker
chmod 777 /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
chmod 644 /etc/sysctl.conf
apt install -y apt-transport-https
apt install -y python3-pip
pip3 install ec2instanceconnectcli
apt install -y mssh
until [[ $(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${region} ubuntu@${master-id} sudo kubectl get no | awk 'NR == 2 {print $2}') == Ready ]]; do echo "master node is not ready"; sleep 3; done;

token=$(mssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${region} ubuntu@${master-id} sudo cat /var/lib/rancher/k3s/server/node-token | awk 'NR==1 {print $1}')

curl -sfL http://get.k3s.io | K3S_URL=https://${master-private}:6443 K3S_TOKEN=$token sh -


