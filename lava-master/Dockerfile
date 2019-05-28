FROM baylibre/lava-master-base:2019.03_stretch

COPY backup /root/backup/

COPY configs/tftpd-hpa /etc/default/tftpd-hpa

COPY default/* /etc/default/

RUN git clone https://github.com/BayLibre/lava-healthchecks.git
RUN cp lava-healthchecks/health-checks/* /etc/lava-server/dispatcher-config/health-checks/
COPY health-checks/* /etc/lava-server/dispatcher-config/health-checks/
RUN if [ -e /etc/lava-server/dispatcher-config/health-checks/healthcheck_url ];then sed -i "s,http.*blob/master,$(cat /etc/lava-server/dispatcher-config/health-checks/healthcheck_url)," /etc/lava-server/dispatcher-config/health-checks/* && sed -i 's,?.*$,,' /etc/lava-server/dispatcher-config/health-checks/* ;fi
RUN chown -R lavaserver:lavaserver /etc/lava-server/dispatcher-config/health-checks/

COPY devices/ /root/devices/
COPY device-types/ /root/device-types/
COPY users/ /root/lava-users/
COPY groups/ /root/lava-groups/
COPY tokens/ /root/lava-callback-tokens/
COPY scripts/setup.sh /

COPY settings.conf /etc/lava-server/

COPY lava-patch/ /root/lava-patch
RUN cd /usr/lib/python3/dist-packages && for patch in $(ls /root/lava-patch/*patch| sort) ; do echo $patch && patch -p1 < $patch || exit $?;done
RUN rsync -avr /usr/lib/python3/dist-packages/lava_scheduler_app/tests/device-types/ /etc/lava-server/dispatcher-config/device-types/

COPY device-types-patch/ /root/device-types-patch/
RUN cd /etc/lava-server/dispatcher-config/device-types/ && for patch in $(ls /root/device-types-patch/*patch) ; do sed -i 's,lava_scheduler_app/tests/device-types/,,' $patch && echo $patch && patch < $patch || exit $?; done
RUN chown -R lavaserver:lavaserver /etc/lava-server/dispatcher-config/device-types/

COPY zmq_auth/ /etc/lava-dispatcher/certificates.d/

COPY lava_http_fqdn /root/

COPY env/ /etc/lava-server/dispatcher.d/

EXPOSE 69/udp 80 3079 5555 5556

CMD /start.sh && while [ true ];do sleep 365d; done
