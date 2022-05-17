FROM python:3.9.5-alpine

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=4.2.1
ARG CHECKSUM_SHA512=980dfab33f7ae1dfb2f9e77272d00919224b7d4267d5f9a298ba082779ef5cc10260926dd5ad75f6ff54c1b5f451bbe4ee3d0c3908db5b54b3546cb5e9ec49f6
LABEL maintainer="osintsev@gmail.com" \
	org.label-schema.vendor="Distirbuted Solutions, Inc." \
	org.label-schema.build-date=$BUILD_DATE \
	org.label-schema.name="Electrum wallet (RPC enabled)" \
	org.label-schema.description="Electrum wallet with JSON-RPC enabled (daemon mode)" \
	org.label-schema.version=$VERSION \
	org.label-schema.vcs-ref=$VCS_REF \
	org.label-schema.vcs-url="https://github.com/osminogin/docker-electrum-daemon" \
	org.label-schema.usage="https://github.com/osminogin/docker-electrum-daemon#getting-started" \
	org.label-schema.license="MIT" \
	org.label-schema.url="https://electrum.org" \
	org.label-schema.docker.cmd='docker run -d --name electrum-daemon --publish 127.0.0.1:7000:7000 --volume /srv/electrum:/data osminogin/electrum-daemon' \
	org.label-schema.schema-version="1.0"

ENV ELECTRUM_VERSION $VERSION
ENV ELECTRUM_USER electrum
ENV ELECTRUM_PASSWORD electrumz		# XXX: CHANGE REQUIRED!
ENV ELECTRUM_HOME /home/$ELECTRUM_USER
ENV ELECTRUM_NETWORK mainnet

# IMPORTANT: always verify gpg signature before changing a hash here!
ENV ELECTRUM_CHECKSUM_SHA512 $CHECKSUM_SHA512

RUN adduser -D $ELECTRUM_USER && \
    apk add libsecp256k1 && \
    apk --no-cache add --virtual build-dependencies gcc musl-dev && \
    wget https://download.electrum.org/${ELECTRUM_VERSION}/Electrum-${ELECTRUM_VERSION}.tar.gz && \
    [ "${ELECTRUM_CHECKSUM_SHA512}  Electrum-${ELECTRUM_VERSION}.tar.gz" = "$(sha512sum Electrum-${ELECTRUM_VERSION}.tar.gz)" ] && \
    echo -e "**************************\n SHA 512 Checksum OK\n**************************" && \
    pip3 install pycryptodomex && \
    pip3 install Electrum-${ELECTRUM_VERSION}.tar.gz && \
    rm -f Electrum-${ELECTRUM_VERSION}.tar.gz && \
    apk del build-dependencies

RUN mkdir -p /data && \
	ln -sf /data ${ELECTRUM_HOME}/.electrum  && \
	chown -R ${ELECTRUM_USER} ${ELECTRUM_HOME}/.electrum /data

USER $ELECTRUM_USER
WORKDIR $ELECTRUM_HOME
VOLUME /data
EXPOSE 7000

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["electrum"]
