FROM debian:jessie

RUN apt-get update && apt-get install -y gnutls-bin iptables libnl-route-3-200 libseccomp2 libwrap0 openssl --no-install-recommends && rm -rf /var/lib/apt/lists/* 

RUN buildDeps=" \
		autoconf \
		autogen \
		ca-certificates \
		curl \
		gcc \
		gperf \
		libgnutls28-dev \
		libnl-route-3-dev \
		libpam0g-dev \
		libreadline-dev \
		libseccomp-dev \
		libwrap0-dev \
		make \
		pkg-config \
		xz-utils \
	"; \
	set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& LZ4_VERSION=`curl "https://github.com/lz4/lz4/releases/latest" | sed -n 's/^.*tag\/\(.*\)".*/\1/p'` \
	&& curl -SL "https://github.com/lz4/lz4/archive/$LZ4_VERSION.tar.gz" -o lz4.tar.gz \
	&& mkdir -p /usr/src/lz4 \
	&& tar -xf lz4.tar.gz -C /usr/src/lz4 --strip-components=1 \
	&& rm lz4.tar.gz \
	&& cd /usr/src/lz4 \
	&& make -j"$(nproc)" \
	&& make install \
	&& OC_VERSION=`curl "http://www.infradead.org/ocserv/download.html" | sed -n 's/^.*version is <b>\(.*$\)/\1/p'` \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz.sig" -o ocserv.tar.xz.sig \
	&& gpg --keyserver pgp.mit.edu --recv-key 96865171 \
	&& gpg --verify ocserv.tar.xz.sig \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm ocserv.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure --enable-linux-namespaces \
	&& make -j"$(nproc)" \
	&& make install \
	&& mkdir -p /etc/ocserv \
	&& cd / \
	&& rm -fr /usr/src/lz4 \
	&& rm -fr /usr/src/ocserv \
	&& apt-get purge -y --auto-remove $buildDeps

# Setup config
COPY ocserv.conf /etc/ocserv/
COPY route.txt /tmp/
RUN set -x \
	&& cat /tmp/route.txt >> /etc/ocserv/ocserv.conf \
	&& rm -fr /tmp/route.txt

WORKDIR /etc/ocserv

COPY vpn.sh /vpn.sh
RUN chmod +x /vpn.sh

EXPOSE 443

CMD ["/vpn.sh"]
