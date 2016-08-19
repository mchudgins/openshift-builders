#
#
#	Golang Builder
#

FROM		debian
MAINTAINER	Mike Hudgins <mchudgins@dstsystems.com> @mchudgins

# update the package repo info
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	  ca-certificates \
		curl \
		git \
		make \
	&& apt-get clean \
	&& rm -r /var/lib/apt/lists/* \
	&& curl -sL https://storage.googleapis.com/golang/go1.7.src.tar.gz -o /go-1.7.tar.gz \
	&& curl -sL https://github.com/tools/godep/releases/download/v74/godep_linux_amd64 -o /usr/local/bin/godep \
	&& chmod +x /usr/local/bin/godep \
	&& curl -sL http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 -o /tmp/upx.tar.bz2 \
		&& cd /tmp && tar xvfj upx.tar.bz2 && mv upx-*-amd64_linux/upx /usr/local/bin && cd - \
	&& mkdir /golang \
	&& mkdir /golang/pkg \
	&& mkdir /golang/src \
	&& mkdir /golang/bin \
	&& chmod o+rwx /golang \
	&& curl -sL https://get.docker.com/builds/Linux/x86_64/docker-1.9.1 -o /usr/local/bin/docker \
	&& chmod +x /usr/local/bin/docker \
	&& cd / \
	&& rm -rf /tmp/*

ENV PATH /bin:/usr/bin:/usr/local/bin:/usr/local/go/bin
ENV GOPATH /golang

ENTRYPOINT ["/entrypoint.sh"]

CMD [ "build" ]

COPY docker-entrypoint.sh /entrypoint.sh
