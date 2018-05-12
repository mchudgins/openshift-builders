#!/usr/bin/env bash
#
# this script (is one of many which) initializes the development cluster with necessary imagestreams and builders
#

function createIS {
    tmpfile=`mktemp`

    cat <<EOF >${tmpfile}
apiVersion: v1
kind: ImageStream
metadata:
  labels:
    created-by: hack-script
    owner: ${USER}
  name: $1
spec:
    name: latest
EOF

    cat ${tmpfile} | oc create -f - && rm ${tmpfile}
}


function createBuildConfig {
    tmpfile=`mktemp`

    cat <<EOF >${tmpfile}
apiVersion: v1
kind: BuildConfig
metadata:
  annotations:
    openshift.io/git-repository: openshift-builders
  labels:
    created-by: hack-script
    owner: ${USER}
  name: s2i-golang
spec:
  failedBuildsHistoryLimit: 3
  successfulBuildsHistoryLimit: 3
  nodeSelector: null
  output:
    to:
      kind: ImageStreamTag
      name: s2i-golang:latest
  runPolicy: Serial
  source:
    contextDir: /s2i-go
    git:
      ref: master
      uri: https://github.com/mchudgins/openshift-builders.git
    type: Git
  strategy:
    dockerStrategy:
      from:
        kind: ImageStreamTag
        name: golang:latest
    type: Docker
  triggers:
  - imageChange: {}
    type: ImageChange
  - type: Generic
    generic:
      secret: aSecretValue
EOF

oc create -f ${tmpfile} && rm ${tmpfile}
}

#########################################
# main line of shell script starts here #
#########################################


# check we're logged in and obtain current list of images
images=`oc get is --template '{{ range .items }} {{ .metadata.name }} {{ end }}'`
if [[ $? -ne 0 ]]; then
    echo "You must be logged into the Openshift cluster.  Server said: "
    echo ${images}
    exit $?
fi

# build these imagestreams & builders in the 'openshift' project
oc project openshift

# create the golang IS
ignore=`oc get is/golang 2>/dev/null`
if [[ $? -ne 0 ]]; then
    oc import-image golang --from=golang:1.10-alpine3.7 --confirm
fi

# create the s2i-golang IS
ignore=`oc get is/s2i-golang 2>/dev/null`
if [[ $? -ne 0 ]]; then
    createIS s2i-golang
fi

# create the s2i-golang build config
ignore=`oc get bc/s2i-golang 2>/dev/null`
if [[ $? -ne 0 ]]; then
    createBuildConfig
fi

