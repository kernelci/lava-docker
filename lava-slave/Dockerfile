FROM baylibre/lava-slave-base:latest

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install cu conmux

COPY configs/lava-slave /etc/lava-dispatcher/lava-slave

COPY configs/tftpd-hpa /etc/default/tftpd-hpa

COPY scripts/cu-loop /usr/local/bin/
COPY conmux/ /etc/conmux/

# Caution to not use any port between the Linux dynamic port range: 32768-60999
RUN find /usr/lib/python3/dist-packages/ -iname constants.py | xargs sed -i 's,XNBD_PORT_RANGE_MIN.*,XNBD_PORT_RANGE_MIN=61950,'
RUN find /usr/lib/python3/dist-packages/ -iname constants.py | xargs sed -i 's,XNBD_PORT_RANGE_MAX.*,XNBD_PORT_RANGE_MAX=62000,'

#conmux need cu >= 1.07-24 See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=336996
RUN echo "deb http://deb.debian.org/debian/ testing main" >> /etc/apt/sources.list.d/testing.list
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install cu
RUN rm /etc/apt/sources.list.d/testing.list

RUN apt-get -y install ser2net
COPY ser2net.conf /etc

# lava-cli dependencies
RUN apt-get -y install python3-setuptools python3-dev python3-zmq
RUN git clone https://git.linaro.org/lava/lavacli.git /root/lavacli && cd /root/lavacli && git checkout v0.7 && python3 setup.py install

COPY phyhostname /root/
COPY scripts/setup.sh .

COPY scripts/setdispatcherip.py /usr/local/bin/
RUN chmod 755 /usr/local/bin/setdispatcherip.py

COPY scripts/retire.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/retire.sh

COPY devices/ /root/devices/

COPY scripts/extra_actions /root/
RUN if [ -x /root/extra_actions ] ; then /root/extra_actions ; fi

RUN apt-get -y install screen openssh-server
RUN ssh-keygen -q -f /root/.ssh/id_rsa
RUN cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys
COPY lava-screen.conf /root/

COPY zmq_auth/ /etc/lava-dispatcher/certificates.d/

EXPOSE 69/udp 80

CMD /start.sh
