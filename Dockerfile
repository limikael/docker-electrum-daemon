FROM python:3.9.5-alpine

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=4.1.4
ARG CHECKSUM_SHA512=1827ba199a3e20630b4d32a5e54cdb86e50c578b4649441c6067069b5c22d1d44fd3fd6d968d36e0cace60d5a5f5a4a9588e104b3378c003050a410a4ea0e01c
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

#RUN mkdir -p /data \
#	  ${ELECTRUM_HOME}/.electrum/wallets/ \
#	  ${ELECTRUM_HOME}/.electrum/testnet/wallets/ \
#	  ${ELECTRUM_HOME}/.electrum/regtest/wallets/ \
#	  ${ELECTRUM_HOME}/.electrum/simnet/wallets/ && \
#	ln -sf ${ELECTRUM_HOME}/.electrum/ /data && \
#	chown -R ${ELECTRUM_USER} ${ELECTRUM_HOME}/.electrum /data

RUN mkdir /data
RUN chown ${ELECTRUM_USER} /data

USER $ELECTRUM_USER
WORKDIR $ELECTRUM_HOME
VOLUME /data
EXPOSE 7000

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["electrum"]
