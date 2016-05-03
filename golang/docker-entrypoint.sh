#!/bin/bash
#set -e

if [[ "$1" = 'build' ]]; then
	DOCKER_SOCKET=/var/run/docker.sock

#	if [ ! -e "${DOCKER_SOCKET}" ]; then
#		echo "Docker socket missing at ${DOCKER_SOCKET}"
#		exit 1
#	fi

	echo "running a build here, boss"
	go version

#	cd /golang/src
#	go get ./...

	echo ls /
	ls -l /

	find . -name \*.go -print

	printenv | sort

	sleep 3600

	exit 0
fi

exec "$@"



