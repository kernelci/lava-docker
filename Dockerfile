FROM kernelci/lava-docker:2017.02

# Add device configuration
COPY jinja/qemu.jinja2 /etc/dispatcher-config/devices/qemu.jinja2

# Create a kernelci user (Insecure note, this creates a default user, username: kernelci/kernelci) and configure devices
RUN /start.sh \
 && echo "from django.contrib.auth.models import User; User.objects.create_superuser('kernelci', 'admin@localhost.com', 'kernelci')" | lava-server manage shell \
 && lava-server manage tokens add --user kernelci \
 && lava-server manage device-types add qemu \
 && lava-server manage add-device --device-type qemu --worker $(hostname) qemu-01 \
 && lava-server manage device-dictionary --hostname qemu-01 --import /etc/dispatcher-config/devices/qemu.jinja2 \
 && /stop.sh

EXPOSE 22 80 5555 5556
CMD /start.sh && bash
