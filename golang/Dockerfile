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
	&& curl -sL https://storage.googleapis.com/golang/go1.6.2.linux-amd64.tar.gz -o /go-1.6.2.tar.gz \
	&& curl -sL https://github.com/tools/godep/releases/download/v62/godep_linux_amd64 -o /usr/local/bin/godep \
	&& chmod +x /usr/local/bin/godep \
	&& mkdir /golang \
	&& mkdir /golang/pkg \
	&& mkdir /golang/src \
	&& mkdir /golang/bin \
	&& chmod o+rwx /golang \
	&& curl -sL https://get.docker.com/builds/Linux/x86_64/docker-1.11.1.tgz -o /tmp/docker.tar.gz \
	&& cd /tmp \
	&& tar xfz docker.tar.gz \
	&& mv docker/docker /usr/local/bin \
	&& cd / \
	&& rm -rf /tmp/*

ENV PATH /bin:/usr/bin:/usr/local/bin:/usr/local/go/bin
ENV GOPATH /golang

ENTRYPOINT ["/entrypoint.sh"]

CMD [ "build" ]

COPY docker-entrypoint.sh /entrypoint.sh
