FROM bitnami/minideb:stretch

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install python3-zmq

COPY create_certificate.py /root/
RUN chmod 750 /root/create_certificate.py
RUN mkdir /root/output

COPY id /root/

COPY zmq_gen.sh /root/
RUN chmod 755 /root/zmq_gen.sh
COPY zmq_genlist /root/

CMD /root/zmq_gen.sh
