FROM alpine as downloader
LABEL maintainer="Ruslan Zhdanov <nl.ruslan@yandex.ru> (@TheDemonCat)"

ARG ONEC_USERNAME
ARG ONEC_PASSWORD
ARG ONEC_VERSION
ARG TYPE=platform83

ARG ONEGET_VERSION=v0.0.7
WORKDIR /tmp

RUN apk add curl tar\
  && cd /tmp \
  %% curl -sL -o oneget http://git.io/oneget.sh \
  && chmod +x oneget \
  && ./oneget --nicks $TYPE --version-filter $ONEC_VERSION --distrib-filter 'deb64_.*.tar.gz$' \
  && rm -f oneget \
  && cd  $TYPE/$ONEC_VERSION \
  && for file in *.tar.gz; do tar -zxf "$file"; done \
  && rm -rf *.tar.gz

FROM ghcr.io/thedemoncat/onec_base:latest as base
LABEL maintainer="Ruslan Zhdanov <nl.ruslan@yandex.ru> (@TheDemonCat)"

ARG ONEC_VERSION
ARG TYPE=platform83

COPY --from=downloader /tmp/$TYPE/$ONEC_VERSION/*.deb /tmp/dist/

RUN set -xe \
    && cd /tmp/dist/ \
    && dpkg -i ./1c-enterprise83-common_*.deb \
        ./1c-enterprise83-server_*.deb \
        ./1c-enterprise83-ws_*.deb \
        ./1c-enterprise83-crs_*.deb \
    && cd .. \
    && rm -rf dist

RUN mkdir -p /root/.1cv8/1C/1cv8/conf/

EXPOSE 1541/tcp
EXPOSE 1560-1591/tcp

COPY ./configs/conf.cfg /opt/1C/v8.3/x86_64/conf/
COPY ./scripts/srv1cv83 /etc/init.d/srv1cv83

COPY ./configs/logcfg.xml /home/usr1cv8/.1cv8/1C/1cv8/conf

USER usr1cv8 

RUN mkdir /home/usr1cv8/srvinfo 

CMD ["/opt/1C/v8.3/x86_64/ragent", "-debug", "-d",  "/home/usr1cv8/srvinfo"]
