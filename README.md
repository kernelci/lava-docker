# Linaro's Automated Validation Architecture (LAVA) Docker Container
Preinstalls and preconfigures the latest LAVA server release.

## Prerequisite
The package docker-compose is necessary

## Name Conventions
Each board must be named by their device-type as "device-type-XX" where XX is a number
Each tty will have a name /dev/boardname (via the udev rules)
Each conmux config file will be named boardname.cf
Each slave must be named lab-slave-XX

## Know limitation
The current lava-docker provide support for only one slave

## Architecture
The host must have a dedicated LAN. (192.168.66.0/24)
The host must have IP set to 192.168.66.1 on this LAN.
A sample dhcpd config file is available in the dhcpd directory

## Generating files
### boards.yaml
This file describe how are setuped your boards, and how they are connected and powered.
```
lab-slave-name:
	devicename:
		type: the devicetype of this device
		pdu:
			daemon: The hostname running the PDU daemon (always localhost)
			host: The host name of the PDU as named in lavapdu.conf
			port: portnumber (The port number of the PDU where the device is connected)
		uart:
			type:
			serial: The serial number in case of FTDI uart
```
Notes:
uart FTDI only need serial

Examples: see boards.yaml

### tokens.yaml
The tokens format have two section, one for user generation, the other for callback tokens
```
lava_server_users:
	- name: LAVA username
	  token: The token of this use
	  password: Password the this user (generated if not provided)
callback_tokens:
  - filename: The filename for storing the informations below, the name should be unique along other callback tokens
    username: The LAVA user owning the token below. (This user should be created via lava_server_users:)
    token: The token for this callback
    description: The description of this token. This string could be used with LAVA-CI.
```
Example: see tokens.yaml

### Generate
```
lavalab-gen.py
```

this scripts will generate all necessary files in the following location:
```
conmux/		All files needed by conmux
tokens/		This is where the callback tokens will be generated
users/		This is where the users will be generated
devices/	All LAVA devices files (note that an extran qemu device is also created for the master)
udev-rules for host
docker-compose.yml	Generated from docker-compose.template
```

All thoses files (except for udev-rules) will be handled by docker.
The udev-rules is for generating the right /dev/xxx TTY names.

You can still hack after generated files.

## Building
To build an image locally, execute the following from the directory you cloned the repo:

```
docker-compose build
```

## Running
```
docker-compose up
```

## Process wrapper
You can use the lavalab-gen.sh wrapper which will do all the above actions

## Security
Note that this container provides defaults which are unsecure. If you plan on deploying this in a production enviroment please consider the following items:

  * Changing the default admin password
  * Using HTTPS
  
