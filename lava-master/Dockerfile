FROM lavasoftware/lava-server:2022.03

RUN apt-get update && apt-get -y install sudo git

COPY backup /root/backup/

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
COPY entrypoint.d/*sh /root/entrypoint.d/

COPY settings.conf /etc/lava-server/

COPY lava-patch/ /root/lava-patch
RUN cd /usr/lib/python3/dist-packages && for patch in $(ls /root/lava-patch/*patch| sort) ; do echo $patch && patch -p1 < $patch || exit $?;done

COPY device-types-patch/ /root/device-types-patch/
RUN sh root/device-types-patch/patch-device-type.sh

COPY lava_http_fqdn /root/

COPY env/ /etc/lava-server/dispatcher.d/
RUN chown -R lavaserver:lavaserver /etc/lava-server/dispatcher.d/

COPY apache2/ /etc/apache2/

# Fixes 'postgresql ERROR:  invalid locale name: "en_US.UTF-8"' when restoring a backup
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen en_US.UTF-8

COPY pg_lava_password /root

# TODO: send this fix to upstream
RUN sed -i 's,find /root/entrypoint.d/ -type f,find /root/entrypoint.d/ -type f | sort,' /root/entrypoint.sh
# TODO: send this fix to upstream
RUN sed -i 's,pidfile =.*,pidfile = "/run/lava-coordinator/lava-coordinator.pid",' /usr/bin/lava-coordinator

EXPOSE 3079 5555 5556

CMD /root/entrypoint.sh && while [ true ];do sleep 365d; done
