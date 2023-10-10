FROM bitnami/minideb:bullseye

RUN apt-get update && apt-get -y install git
RUN git clone https://github.com/kernelci/lava-healthchecks-binary.git lava-healthchecks-binary

FROM nginx:mainline-alpine

COPY port.conf /etc/nginx/conf.d/

COPY --from=0 /lava-healthchecks-binary/healthchecks /usr/share/nginx/html/healthchecks/
