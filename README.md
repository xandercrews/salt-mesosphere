# mesosphere installation

## prerequisites

 * Ubuntu 14.04 LTS (Trusty) VM to install a salt master

## salt master installation 

_from a release candidate of v2015.02_

```
apt-get install -y vim curl python-pip git unzip
curl -o install_salt.sh -L https://bootstrap.saltstack.com
sh install_salt.sh -M git v2015.2.0rc2
pip install softlayer
```

## salt master configuration and mesosphere assets

_we patch the softlayer plugin, sadly_

download a ZIP file of this git repository and copy it to your salt master

```
cd /tmp
unzip ~/mesosphere-salt-master.zip
cd mesosphere-salt-master
cp -a root/* /
restart salt-master
```

```
vim /etc/salt/cloud.prov*/*
```

edit the file to configure cloud provider parameters:
 * username 
 * api key 
 * master ip, i.e.:

```
  ip addr show dev eth0 | awk '/inet / { print $2 }' | cut -d'/' -f1
```

*optional* generate an ssh key and copy it into the salt filesystem for easy access to nodes

```
ssh-keygen
cp ~/.ssh/id_rsa.pub /srv/salt/ssh_keys/master.id_rsa.pub
```

## mesosphere master bootstrapping  

_try 3 or 5 master nodes, or a number s.t. a quorum is achieved with n/2+1 nodes_


create mesos master nodes.  they will immediately start synchronizing their state once 
they are created, and then we use linear orchestration to clear the zookeeper log any
time we change the size of the master cluster.

```
salt-cloud -P -p sl_ubuntu_mesomaster_small mesosmaster{1,2,3}
salt-run state.orch mesosphere.mastersync
```

# use mesosphere 

determine the ip of any mesos master and try to access the web interface on http port 5050.  

```
salt -G 'mesos:master' network.ip_addrs interface=eth1
```

you will be redirected to the elected master

try to access marathon on any mesos master, http port 8080

## submit a sample job

```
cat <<\EOF > ~/sample-job.json
{
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "libmesos/ubuntu"
    }
  },
  "id": "marathon-docker-sample",
  "instances": 20,
  "cpus": 0.20,
  "mem": 64,
  "uris": [],
  "cmd": "while sleep 10; do date -u +%T; done"
}
EOF

curl -XPOST -H "Content-Type: application/json" http://<marathon-node>:8080/v2/apps -d @/root/sample-job.json
```

## watch a sample scaling script

```
while [[ 1 ]]; do python /srv/scaler/scaler.py; sleep 30; done
```

