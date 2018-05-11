#
#
#	Golang Builder
#

FROM		golang
MAINTAINER	Mike Hudgins <mchudgins@dstsystems.com> @mchudgins

ENV PROTOC_VERSION 3.5.1

RUN	apk add --no-cache curl git make zip \
	&& echo "ls -l /usr/local/go/pkg" && ls -l /usr/local/go/pkg \
	&& cd /tmp \
	&& curl -sL https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o /tmp/protoc.zip \
	&& unzip /tmp/protoc.zip \
	&& cp /tmp/bin/protoc /usr/local/bin \
	&& cp -ra /tmp/include/* /usr/local/include/ \
	&& cd - \
	&&		go get -u github.com/jteeuwen/go-bindata/... \
	&&		go get -u github.com/elazarl/go-bindata-assetfs/... \
	&&		go get -u github.com/mchudgins/gostatic/... \
	&&		go get golang.org/x/tools/cmd/goimports \
	&&		go get -u golang.org/x/lint/golint \
	&&		go get honnef.co/go/tools/cmd/staticcheck \
	&&		go get -u github.com/golang/dep/cmd/dep \
	&&		go get google.golang.org/grpc \
	&&		go get -u github.com/golang/protobuf/proto \
	&&		go get -u github.com/golang/protobuf/protoc-gen-go \
	&&		go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway \
	&&		go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger \
	&&      rm -rf ${GOPATH}/pkg/* \
	&& CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install -i -a -v std \
	&& rm -rf /tmp/* \
	&& rm -rf ${GOPATH}/src/* \
	&& chmod -R a+w ${GOPATH}/pkg \
	&& ls -l ${GOPATH} \
	&& echo "The following apps are now installed into ${GOPATH}/bin:" \
	&& ls -l ${GOPATH}/bin \
	&& echo "ls -l /usr/local/go/pkg" && ls -l /usr/local/go/pkg

USER 1001
LABEL io.openshift.s2i.assemble-user 1001
LABEL io.openshift.s2i.scripts-url image://$GOPATH/.s2i

COPY s2i/ $GOPATH/.s2i
