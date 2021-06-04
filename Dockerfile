FROM alpine as downloader
LABEL maintainer="Ruslan Zhdanov <nl.ruslan@yandex.ru> (@TheDemonCat)"

ARG ONEC_USERNAME
ARG ONEC_PASSWORD
ARG ONEC_VERSION
ARG TYPE=platform83

ARG ONEGET_VERSION=v0.1.10
WORKDIR /tmp

RUN apk add curl bash\
  && cd /tmp \
  && curl -sL http://git.io/oneget.sh > oneget \
  && chmod +x oneget \ 
  && ./oneget --nicks $TYPE --version-filter $ONEC_VERSION --distrib-filter 'deb64_.*.tar.gz$' --extract --rename

FROM demoncat/onec-base:latest as base
LABEL maintainer="Ruslan Zhdanov <nl.ruslan@yandex.ru> (@TheDemonCat)"

ARG ONEC_VERSION
ARG TYPE=platform83

COPY --from=downloader /tmp/pack/*.deb /tmp/dist/

RUN set -xe \
    && cd /tmp/dist/ \
    && dpkg -i ./common-*.deb \
        ./server-*.deb \
        ./ws-*.deb \
        ./crs-*.deb \
    && cd .. \
    && rm -rf dist

RUN mkdir -p /root/.1cv8/1C/1cv8/conf/

EXPOSE 1541/tcp
EXPOSE 1560-1591/tcp

COPY ./configs/conf.cfg /opt/1C/v8.3/x86_64/conf/
COPY ./scripts/srv1cv83 /etc/init.d/srv1cv83

COPY ./configs/logcfg.xml /home/usr1cv8/.1cv8/1C/1cv8/conf

COPY ./scripts/create_symlink.sh create_symlink.sh

RUN set -e \
  && chmod +x create_symlink.sh \
  && ./create_symlink.sh $ONEC_VERSION

USER usr1cv8 

RUN mkdir /home/usr1cv8/srvinfo 

CMD ["ragent", "-debug", "-d",  "/home/usr1cv8/srvinfo"]
