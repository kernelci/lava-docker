FROM bitnami/minideb:stretch

RUN echo "deb http://deb.debian.org/debian/ stretch-backports main" >> /etc/apt/sources.list

RUN apt-get update

# Install debian packages used by the container
# Configure apache to run the lava server
# Log the hostname used during install for the slave name
RUN echo 'lava-server   lava-server/instance-name string lava-docker-instance' | debconf-set-selections \
 && echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections \
 && echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections

# e2fsprogs is for libguestfs
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
 locales \
 postgresql \
 screen \
 sudo \
 wget \
 e2fsprogs \
 gnupg \
 vim

RUN wget http://images.validation.linaro.org/production-repo/production-repo.key.asc \
 && apt-key add production-repo.key.asc \
 && echo 'deb http://images.validation.linaro.org/production-repo/ stretch-backports main' > /etc/apt/sources.list.d/lava.list \
 && apt-get clean && apt-get update

RUN service postgresql start \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install lava \
 && sudo -u postgres psql lavaserver -c "DELETE FROM lava_scheduler_app_worker WHERE lava_scheduler_app_worker.hostname = 'example.com';" \
 && service postgresql stop

RUN a2enmod proxy \
 && a2enmod proxy_http \
 && a2dissite 000-default \
 && a2ensite lava-server

# Add services helper utilities to start and stop LAVA
COPY scripts/stop.sh .
COPY scripts/start.sh .
COPY scripts/lava-logs /etc/init.d/
RUN chmod 755 /etc/init.d/lava-logs
COPY scripts/lava-master /etc/init.d/
RUN chmod 755 /etc/init.d/lava-master
COPY scripts/lava-slave /etc/init.d/
RUN chmod 755 /etc/init.d/lava-slave
COPY scripts/lava-server-gunicorn /etc/init.d/
RUN chmod 755 /etc/init.d/lava-server-gunicorn

RUN dpkg -l | grep lava

EXPOSE 80 3079 5555 5556

CMD /start.sh && while [ true ];do sleep 365d; done
