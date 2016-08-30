#
#
#	Golang Builder
#

FROM		debian
MAINTAINER	Mike Hudgins <mchudgins@dstsystems.com> @mchudgins

# update the package repo info
RUN apt-get update -q \
	&& apt-get install -q -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		curl \
		git \
		make \
		unzip \
	&& apt-get clean \
	&& rm -r /var/lib/apt/lists/* \
	&& curl -sL https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz -o /tmp/go-1.7.tar.gz \
	&& cd /usr/local && tar xfz /tmp/go-1.7.tar.gz && cd - \
	&& curl -sL https://github.com/tools/godep/releases/download/v74/godep_linux_amd64 -o /usr/local/bin/godep \
	&& chmod +x /usr/local/bin/godep \
	&& echo 'downloading upx...' \
	&& curl -sL http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 -o /tmp/upx.tar.bz2 \
		&& ls /tmp \
		&& cd /tmp && tar xvfj /tmp/upx.tar.bz2 && mv upx-*-amd64_linux/upx /usr/local/bin && cd - \
	&& echo 'downloading protoc' \
	&& cd /tmp \
	&& curl -sL https://github.com/google/protobuf/releases/download/v3.0.0/protoc-3.0.0-linux-x86_64.zip -o /tmp/protoc.zip \
	&& unzip /tmp/protoc.zip \
	&& cp /tmp/bin/protoc /usr/local/bin \
	&& cd - \
	&& mkdir /golang \
	&& mkdir /golang/pkg \
	&& mkdir /golang/src \
	&& mkdir /golang/bin \
	&& chmod o+rwx /golang \
	&& curl -sL https://get.docker.com/builds/Linux/x86_64/docker-1.9.1 -o /usr/local/bin/docker \
	&& chmod +x /usr/local/bin/docker \
	&& cd / \
	&& PATH=${PATH}:/usr/local/go/bin GOPATH=/golang \
			go get google.golang.org/grpc \
	&& PATH=${PATH}:/usr/local/go/bin GOPATH=/golang \
			go get -u github.com/golang/protobuf/proto \
	&& PATH=${PATH}:/usr/local/go/bin GOPATH=/golang \
			go get -u github.com/golang/protobuf/protoc-gen-go \
	&& PATH=${PATH}:/usr/local/go/bin GOPATH=/golang \
			go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway \
	&& PATH=${PATH}:/usr/local/go/bin GOPATH=/golang \
			go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger \
	&& PATH=${PATH}:/usr/local/go/bin GOPATH=/golang \
			go get -u github.com/jteeuwen/go-bindata \
	&& rm -rf /tmp/*

ENV GOPATH /golang
ENV PATH /bin:/usr/bin:/usr/local/bin:/usr/local/go/bin:${GOPATH}/bin

ENTRYPOINT ["/entrypoint.sh"]

CMD [ "build" ]

COPY docker-entrypoint.sh /entrypoint.sh
