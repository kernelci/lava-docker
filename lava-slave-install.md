This is an howto install a lava-docker slave
This howto is based on a Debian host.
Along with this file, you could see standalone-slave.yaml.example file.
The rest of the document is based on that example.

# Create a dedicated user
The user will be lavadocker in our example. It must be in the docker group for doing docker operations.
```
useradd -G docker lavadocker
```

# Install all pre-requisites packages
docker-compose need to be installed from PIP
```
apt-get install git python-pip
```

# Install docker-ce
See https://docs.docker.com/install/linux/docker-ce/debian/ for more detailled informations.

# install docker-compose for our user

As lavadocker run:
```
pip install --user docker-compose
```

# Install a second network interface
Having a dedicated network for boards is recommanded.
Anyway, we will call enx0 the network card wired on the network connected to DUTs. (Whatever it is dedicated or not)

# Install a DHCPD listenning on enx0
You need to have a DHCPD on the network where your boards are.
You have many choices, for our examples we will use isc-dhcp-server:
```
apt-get install isc-dhcp-server
```

## Configure the DHCPD server
```
sed -i 's,INTERFACESv4="",INTERFACESv4="enx0",' /etc/default/isc-dhcp-server
```

Add the following to /etc/dhcp/dhcpd.conf
```
subnet 192.168.66.0 netmask 255.255.255.0 {
  range 192.168.66.11 192.168.66.250;
	option routers 192.168.66.1;
}
```
The IP range is an example. You can use whatever you want BUT your need that enx0 to be in the same IP network. (network accessible from the IP given by DHCPD)
In this example enx0 can be 192.168.66.1.

# Checkout lava-docker sources
As lavadocker run:
```
git clone https://github.com/kernelci/lava-docker.git
```

# Create your slave configuration file
## Create your own file
Copy standalone-slave.yaml.example to standalone-slave.yaml

## Get the following required values from the LAVA master administrator
* A remote username (remote_user)
* A remote token for this username (remote_user_token)
* The FQDN for connecting to the master (remote_master)
* ZMQ public key for LAVA master (if encryption is required, see below)

In our standalone-slave.yaml it will be:
```
    remote_master: lava.example.com
    remote_user: lab-extern
    remote_user_token: lab-extern-randomtoken
    zmq_auth_master_key: master-public.key
```

## Optional ZMQ keys
If the master is using ZMQ encryption you need to:
### Generate ZMQ keys
Generate thoses keys via:
```
zmqauth/zmq_auth_gen/create_certificate.py --directory . nameofyourslave
```
This will produce two files:
* A public key ending with ".key" (set it as zmq_auth_key)
* A private key ending with ".key_secret (set it as zmq_auth_key_secret)

### slave public key
Give the slave public key to the master's admin

### master public key
Get the master public key from the master's admin and set it as "zmq_auth_master_key" in master node.
Note: you dont need master private key (or need to touch a fake one).

# Generate files
As lavadocker run:
```
./lavalab-gen.py standalone-slave.yaml
```

# Run deploy.sh in the generated directory
```
cd output/externpc/
./deploy.sh
```

deploy.sh will
- Deploy udev rules
- Build images
- Run the final images
