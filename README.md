# Linaro's Automated Validation Architecture (LAVA) Docker Container
Preinstalls and preconfigures the latest LAVA server release.

## Building
To build an image locally, execute the following from the directory you cloned the repo:

```
sudo docker build -t lava .
```

## Running
To run the image from a host terminal / command line execute the following:

```
sudo docker run -it -v /dev:/dev -p 69:69 -p 80:80 -p 5555:5555 -p 5556:5556 -h <HOSTNAME> --privileged kernelci/lava-docker-v2:latest
```
Where HOSTNAME is the hostname used during the container build process (check the docker build log), as that is the name used for the worker configuration. You can use `lava-docker` as the pre-built container hostname.

## Runtime Enviroment
Enviroment variables are available to help setup state within the container.

```
sudo docker run -it -v /dev:/dev -p 69:69 -p 80:80 -p 5555:5555 -p 5556:5556 -e LAVA_API_TOKEN='<token>' -h <HOSTNAME> --privileged kernelci/lava-docker-v2:latest
```
Where LAVA_API_TOKEN is the token for your kernelci user.

```
sudo docker run -it -v /dev:/dev -p 69:69 -p 80:80 -p 5555:5555 -p 5556:5556 -e LAVA_API_TOKEN='<token>' -e LAVA_SERVER_IP='<docker host ip>' -h <HOSTNAME> --privileged kernelci/lava-docker-v2:latest
```

Where LAVA_SERVER_IP is the IP of your Docker host. This allows the TFTP service to properly address the TFTP transfers.
