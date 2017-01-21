#!/bin/bash

GO_ARCHIVE=/go-1.7.tar.gz

export PATH=${PATH}:/usr/local/go/bin

if [[ -z "${GOPATH}" ]]; then
	GOPATH=/golang
fi

set -o pipefail
IFS=$'\n\t'

if [[ ${BUILD_LOGLEVEL} -gt 1 ]]; then
	printenv | sort
fi

function goCompile {
	pushd $1 >/dev/null
	TARGET=`echo ${SOURCE_REPOSITORY} | sed 's!\(http://\)\|\(https://\)!!' | sed 's/\.git//'`
	mkdir -p /golang/src/${TARGET}
	cp -ra * /golang/src/${TARGET}
	cp -ra .* /golang/src/${TARGET} 2>/dev/null
	popd >/dev/null

	pushd /golang/src/${TARGET} >/dev/null
	if [[ -f Makefile ]]; then
		if [[ ${BUILD_LOGLEVEL} -gt 1 ]]; then
			echo "Current working directory: " `pwd`
			echo "Source contents:"
			ls -Al
		fi
		echo "Running make all"
		make all
		if [ $? != 0 ]; then
	    echo "Error detected with 'make all'. Exiting."
	    exit 1
	  fi
		return
	fi

	if [[ -d Godeps ]]; then
		echo "godep restore"
		godep restore
		echo "godep go build"
		godep go build
	else
		echo go get ./...
		go get ./...
		echo go build
		go build
	fi
	popd >/dev/null
}

if [[ "$1" = 'build' ]]; then
	echo "Building ${SOURCE_REPOSITORY}, branch ${SOURCE_REF} using image ${OPENSHIFT_BUILD_NAMESPACE}/${OPENSHIFT_BUILD_NAME}(${OPENSHIFT_BUILD_REFERENCE})"
	# install go
#	if [[ ! -f ${GO_ARCHIVE} ]]; then
#		echo "The go archive (${GO_ARCHIVE}) is missing.  Exiting..."
#		exit 1
#	fi
#
#	pushd /usr/local >/dev/null \
#		&& tar xfz ${GO_ARCHIVE} \
#		&& popd >/dev/null

#
# set git config info
#
git config --global --add user.name ${OPENSHIFT_BUILD_NAMESPACE}-${OPENSHIFT_BUILD_REFERENCE}-${OPENSHIFT_BUILD_NAME}
git config --global --add user.email golang-builder@dstresearch.com

	if [[ ${BUILD_LOGLEVEL} -gt 1 ]]; then
		go version
		echo "Docker version:"
		docker version
	fi

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
	  if [ $? != 0 ]; then # the Openshift gitserver only responds to /HEAD url
            curl --silent --fail --location --max-time 16 $URL/HEAD > /dev/null
	    if [ $? != 0 ]; then
	      echo "Could not access source url: ${SOURCE_REPOSITORY}"
	      exit 1
	    fi
	  fi
	fi

	if [ -n "${SOURCE_REF}" ]; then
	  BUILD_DIR=$(mktemp --directory)
		echo "git clone --recursive ${SOURCE_REPOSITORY} ${BUILD_DIR}"
	  git clone --recursive "${SOURCE_REPOSITORY}" "${BUILD_DIR}" >>/tmp/git.lis
#		GIT_REPO=`echo ${SOURCE_REPOSITORY} | sed 's|^https://||' | sed 's|^http://||' | sed 's|^git://||' | sed 's|^git@||' | sed 's|\.git$||'`
#		echo "go get ${GIT_REPO}"
#		go get ${GIT_REPO}
	  if [ $? != 0 ]; then
	    echo "Error trying to fetch git source: ${SOURCE_REPOSITORY}"
	    exit 1
	  fi

	  pushd "${BUILD_DIR}" >/dev/null
		echo "git checkout ${SOURCE_REF} (in subdirectory ${BUILD_DIR})"
	  git checkout "${SOURCE_REF}" >>/tmp/git.lis
	  if [ $? != 0 ]; then
	    echo "Error trying to checkout branch: ${SOURCE_REF}"
	    exit 1
	  fi
	  popd >/dev/null
		goCompile "${BUILD_DIR}"
		TARGET=`echo ${SOURCE_REPOSITORY} | sed 's!\(http://\)\|\(https://\)!!' | sed 's/\.git//'`
	  docker build --rm -t "${TAG}" "${GOPATH}/src/${TARGET}/docker"
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
