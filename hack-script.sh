#! /bin/bash
oc login --insecure-skip-tls-verify https://mch-dev.dstresearch.com:8443
oc new-project mch
oc import-image debian --from debian --confirm
oc get is
oc describe is/debian
oc create -f generic-builder-template.json
oc new-app --template docker-imagestream-builder -p IMAGESTREAM=golang,CONTEXT_DIR=/golang,GIT_REF=master,GIT_URI=https://github.com/mchudgins/openshift-builders.git,BASE_IMAGESTREAM=debian:latest
oc start-build bc/golang
oc logs --follow golang-1-build
