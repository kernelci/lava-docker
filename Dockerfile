FROM kernelci/lava-docker:2017.04

# Add device configuration
COPY devices/* /etc/dispatcher-config/devices/

COPY scripts/setup.sh .

EXPOSE 22 80 5555 5556
CMD /start.sh && /setup.sh && bash
