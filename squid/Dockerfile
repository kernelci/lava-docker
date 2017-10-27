FROM debian:9

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y squid3

COPY entrypoint.sh /sbin/entrypoint.sh
COPY squid.conf /etc/squid/squid.conf
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 3128/tcp
CMD "/sbin/entrypoint.sh"
