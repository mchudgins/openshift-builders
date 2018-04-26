#
#
#	Golang Builder
#

FROM		golang
MAINTAINER	Mike Hudgins <mchudgins@dstsystems.com> @mchudgins

ENV PROTOC_VERSION 3.5.1

# update the package repo info
#RUN apt-get update -q \
#	&& apt-get install -q -y --no-install-recommends \
#	&& echo 'downloading upx...' \
#	&& curl -sL http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 -o /tmp/upx.tar.bz2 \
#		&& ls /tmp \
#		&& cd /tmp && tar xvfj /tmp/upx.tar.bz2 && mv upx-*-amd64_linux/upx /usr/local/bin && cd - \
#	&& echo 'downloading protoc' \
RUN	apk add --no-cache curl git make zip \
	&& cd /tmp \
	&& curl -sL https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o /tmp/protoc.zip \
	&& unzip /tmp/protoc.zip \
	&& cp /tmp/bin/protoc /usr/local/bin \
	&& cp -ra /tmp/include/* /usr/local/include/ \
	&& cd - \
	&&		go get google.golang.org/grpc \
	&&		go get -u github.com/golang/protobuf/proto \
	&&		go get -u github.com/golang/protobuf/protoc-gen-go \
	&&		go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway \
	&&		go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger \
	&&		go get -u github.com/jteeuwen/go-bindata/... \
	&&		go get -u github.com/elazarl/go-bindata-assetfs/... \
	&&		go get -u github.com/mchudgins/gostatic/... \
	&&		go get golang.org/x/tools/cmd/goimports \
	&&		go get -u golang.org/x/lint/golint \
	&&		go get honnef.co/go/tools/cmd/staticcheck \
	&&		go get -u github.com/golang/dep/cmd/dep \
	&& rm -rf /tmp/* \
	&& rm -rf ${GOPATH}/src/* \
	&& echo "The following apps are now installed into ${GOPATH}/bin:" \
	&& ls -l ${GOPATH}/bin

ENV PATH ${PATH}:${GOPATH}/bin

ENTRYPOINT ["/entrypoint.sh"]

CMD [ "build" ]

COPY docker-entrypoint.sh /entrypoint.sh
