FROM baylibre/lava-master-base:latest

COPY backup /

COPY configs/tftpd-hpa /etc/default/tftpd-hpa

RUN git clone https://github.com/BayLibre/lava-healthchecks.git
RUN cp lava-healthchecks/health-checks/* /etc/lava-server/dispatcher-config/health-checks/
COPY health-checks/* /etc/lava-server/dispatcher-config/health-checks/

COPY devices/ /root/devices/
COPY device-types/ /root/device-types/
COPY users/ /root/lava-users/
COPY tokens/ /root/lava-callback-tokens/
COPY scripts/setup.sh /

#uncomment if you want to use squid
# warning the address used must be network accessible by all slave
#RUN sed -i 's,^.*http_proxy:.*,  http_proxy: http://squid:3128,' /etc/lava-server/env.yaml

#comment this if you do HTTPS (For reenabling CSRF cookie)
COPY settings.conf /etc/lava-server/

COPY device-types-patch/ /root/device-types-patch/
RUN cd /etc/lava-server/dispatcher-config/device-types/ && for patch in $(ls /root/device-types-patch/*patch) ; do sed -i 's,lava_scheduler_app/tests/device-types/,,' $patch && patch < $patch || exit $?; done

COPY lava-patch/ /root/lava-patch
RUN cd /usr/lib/python3/dist-packages && for patch in $(ls /root/lava-patch/*patch) ; do patch -p1 < $patch || exit $?;done

COPY zmq_auth/ /etc/lava-dispatcher/certificates.d/

COPY lava_http_fqdn /root/

EXPOSE 69/udp 80 3079 5555 5556

CMD /start.sh && while [ true ];do sleep 365d; done
