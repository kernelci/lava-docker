#!/bin/bash
echo "from django.contrib.auth.models import User; User.objects.create_superuser('kernelci', 'admin@localhost.com', 'kernelci')" | lava-server manage shell
lava-server manage tokens add --user kernelci
lava-server manage pipeline-worker --hostname $(hostname)
lava-server manage device-types add qemu
lava-server manage add-device --device-type qemu --worker $(hostname) qemu-01
lava-server manage device-dictionary --hostname qemu-01 --import /etc/dispatcher-config/devices/qemu.jinja2
