# Linaro's Automated Validation Architecture (LAVA) Docker Container

## Introduction

The goal of lava-docker is to simplify the install and maintenance of
a LAVA lab in order to participate in distributed test efforts such as
kernelCI.org.

With lava-docker, you describe the devices under test (DUT) in a
simple YAML file, and then a custom script will generate the necessary
LAVA configuration files automatically.

Similarly, LAVA users and authentication tokens are described in
a(nother) YAML file, and the LAVA configurations are automatically generated.

This enables the setup of a LAVA lab with minimal knowledge of the
underlying LAVA configuration steps necessary.

## Prerequisites
lava-docker has currently been tested primarily on Debian stable (stretch).
The following packages are necessary on the host machine:
* docker
* docker-compose

## Quickstart
Example to use lava-docker with only one QEMU device:

* Checkout the lava-docker repository
* You will obtain the following boards.yaml
```
lab-slave-0:
  boardlist:
    qemu-01:
      type: qemu
```
* Generate configuration files for LAVA, udev, serial ports, etc. via
```
./lavalab-gen.py
```
* Build docker images via
```
docker-compose build
```
* Start all images via
```
docker-compose up -d
```

* Once launched, you can access the LAVA web interface via http://localhost:10080/.
With the default users, you can login with admin:admin.

* By default, a LAVA healthcheck job will be run on the qemu device.
You will see it in the "All Jobs" list: http://localhost:10080/scheduler/alljobs

* You can also see full job output by clicking the blue eye icon ("View job details") (or via http://localhost:10080/scheduler/job/1 since it is the first job ran)

* For more details, see https://validation.linaro.org/static/docs/v2/first-job.html

## Known limitations
The current lava-docker provides support for generating only one LAVA slave.
But many slaves could be managed by simply add their name in boards.yaml

## Architecture
The setup is composed of a host which runs the following docker images and DUT to be tested.<br/>
* lava-master: run lava-server along with the web interface
* lava-slave: run lava-dispatcher, the compoment which sends jobs to DUTs
* squid: an HTTP proxy for caching downloaded contents (kernel/dtb/rootfs)

The host and DUTs must share a common LAN.<br/>
The host IP on this LAN must be set as dispatcher_ip in boards.yaml.<br/>

Since most DUTs are booted using TFTP, they need DHCP for gaining network connectivity.<br/>
So, on the LAN shared with DUTs, a running DHCPD is necessary. (See DHCPD below)<br/>

![lava-docker diagram](doc/lava-docker.png)

### Power supply
You need to have a PDU for powering your DUT.
Managing PDUs is done by lavapdu-daemon.

See https://github.com/pdudaemon for more information

### Network ports
The following ports are used by lava-docker and are proxyfied on the host:
- 69/UDP	proxyfied to the slave for TFTP
- 80		proxyfied to the slave for TODO (transfer overlay)
- 5555		proxyfied to the master (LAVA logger)
- 5556		proxyfied to the master (LAVA master)
- 10080		proxyfied to the master (Web interface)
- 55950-56000	proxyfied to the slave for NBD

### DHCPD
A DHCPD service is necessary for giving network access to DUT.

The DHCPD server could be anywhere with the condition that it is accessible of DUTs. (Could be on host, in a docker in the host, or is the ISP box on the same LAN.<br/>

### Examples
Examples are provided with a dedicated LAN. (192.168.66.0/24)
The host (192.168.66.1) run lava-docker.
A DHCPD give address in range of 192.168.66.3-192.168.66.200

So the dispatcher_ip is set to 192.168.66.1

#### DHCPD examples:
##### isc-dhcpd-server
A sample isc-dhcpd-server DHCPD config file is available in the dhcpd directory.<br/>
##### dnsmasq
Simply set interface=interfacename where interfacename is your shared LAN interface

## Generating files

### boards.yaml
This file describe how the DUTs are connected and powered.
```
lab-slave-XX:		The name of the slave (where XX is a number)
  dispatcher_ip: the IP where the slave could be contacted. In lava-docker it is the host IP since docker proxify TFTP from host to the slave.
  boardlist:
    devicename:	Each board must be named by their device-type as "device-type-XX" (where XX is a number)
      type: the LAVA device-type of this device
      macaddr: (Optional) the MAC address to set in uboot
      pdu:
        daemon: The hostname running the PDU daemon (always localhost)
        host: The host name of the PDU as named in lavapdu.conf
        port: portnumber (The port number of the PDU where the device is connected)
      uart:
        type: (unused)
	idvendor: The VID of the UART
	idproduct: the PID of the UART
        serial: The serial number in case of FTDI uart
        devpath: the UDEV devpath to this uart for UART without serial number
```
Notes on UART:
* Only one of devpath/serial is necessary.
* For finding the right devpath, you could use
```
udevadm info -a -n /dev/ttyUSBx |grep devpath
```

Examples: see [boards.yaml.example](boards.yaml.example)

### tokens.yaml
The tokens format has two sections, one for LAVA users, the other for callback tokens
```
lava_server_users:
  - name: LAVA username
    token: The token of this user
    password: Password the this user (generated if not provided)
    superuser: yes/no (default no)
    staff: yes/no (default no)
callback_tokens:
  - filename: The filename for storing the informations below, the name should be unique along other callback tokens
    username: The LAVA user owning the token below. (This user should be created via lava_server_users:)
    token: The token for this callback
    description: The description of this token. This string could be used with LAVA-CI.
```
Example: see [tokens.yaml](tokens.yaml)

### Generate
```
lavalab-gen.py
```

this script will generate all necessary files in the following locations:
```
conmux/		All files needed by conmux
tokens/		This is where the callback tokens will be generated
users/		This is where the users will be generated
devices/	All LAVA devices files
slaves/		Contain the dispatcher_ip to give to slave node
udev-rules for host
docker-compose.yml	Generated from docker-compose.template
```

All thoses file (except for udev-rules) will be handled by docker.

You can still hack after all generated files.

#### udev rules
Note that the udev-rules are generated for the host, they must be placed in /etc/udev/rules.d/
They are used for giving a proper /dev/xxx name to tty devices. (where xxx is the board name)
(lavalab-gen.sh will do it for you)

## Building
To build all docker images, execute the following from the directory you cloned the repo:

```
docker-compose build
```

## Running
For running all images, simply run:
```
docker-compose up -d
```

## Helper script
You can use the lavalab-gen.sh helper script which will do all the above actions for you.

## Proxy cache
A squid docker is provided for caching all LAVA downloads (image, dtb, rootfs, etc...)<br/>
You have to uncomment a line in lava-master/Dockerfile to enable it.<br/>
Note that the squid proxy is always built and run.

## Security
Note that this container provides defaults which are unsecure. If you plan on deploying this in a production enviroment please consider the following items:

  * Changing the default admin password (in tokens.taml)
  * Using HTTPS
  * Re-enable CSRF cookie (disabled in lava-master/Dockerfile)
