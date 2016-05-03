#!/bin/bash

GO_ARCHIVE=/go-1.6.2.tar.gz

set -o pipefail
IFS=$'\n\t'

printenv | sort

function goCompile {
	pushd $1
	ls -l
	mkdir /golang/src/app
	cp -ra * /golang/src/app
	popd

	pushd /golang/src/app
	ls -l
	if [[ -d Godeps ]]; then
		godep restore
		godep go build
	else
		go get ./...
		go build
	fi
	ls -l
	popd
}

# install go
if [[ ! -f ${GO_ARCHIVE} ]]; then
	echo "The go archive (${GO_ARCHIVE}) is missing.  Exiting..."
	exit 1
fi

pushd /usr/local \
	&& tar xfz ${GO_ARCHIVE} \
	&& popd \
	&& go version \
	&& docker version

#
if [[ "$1" = 'build' ]]; then
	DOCKER_SOCKET=/var/run/docker.sock

	if [ ! -e "${DOCKER_SOCKET}" ]; then
		echo "Docker socket missing at ${DOCKER_SOCKET}"
		exit 1
	fi

	if [ -n "${OUTPUT_IMAGE}" ]; then
	  TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
	fi

	if [[ "${SOURCE_REPOSITORY}" != "git://"* ]] && [[ "${SOURCE_REPOSITORY}" != "git@"* ]]; then
	  URL="${SOURCE_REPOSITORY}"
	  if [[ "${URL}" != "http://"* ]] && [[ "${URL}" != "https://"* ]]; then
	    URL="https://${URL}"
	  fi
	  curl --head --silent --fail --location --max-time 16 $URL > /dev/null
	  if [ $? != 0 ]; then
	    echo "Could not access source url: ${SOURCE_REPOSITORY}"
	    exit 1
	  fi
	fi

	if [ -n "${SOURCE_REF}" ]; then
	  BUILD_DIR=$(mktemp --directory)
	  git clone --recursive "${SOURCE_REPOSITORY}" "${BUILD_DIR}"
	  if [ $? != 0 ]; then
	    echo "Error trying to fetch git source: ${SOURCE_REPOSITORY}"
	    exit 1
	  fi
	  pushd "${BUILD_DIR}"
	  git checkout "${SOURCE_REF}"
	  if [ $? != 0 ]; then
	    echo "Error trying to checkout branch: ${SOURCE_REF}"
	    exit 1
	  fi
	  popd
		goCompile "${BUILD_DIR}"
	  docker build --rm -t "${TAG}" "${BUILD_DIR}"
	else
	  docker build --rm -t "${TAG}" "${SOURCE_REPOSITORY}"
	fi

	if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
	  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
	fi

	if [ -n "${OUTPUT_IMAGE}" ] || [ -s "/root/.dockercfg" ]; then
	  docker push "${TAG}"
	fi

	exit 0
fi

exec "$@"
