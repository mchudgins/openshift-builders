#! /bin/bash
if [[ -z $1 ]]; then
	HOST=https://localhost:8443
else
	HOST=$1
fi
sudo docker pull debian:latest
oc login --insecure-skip-tls-verify ${HOST}
oc new-project mch
oc import-image debian --from debian --confirm
oc get is
oc describe is/debian
REGISTRY=`sudo docker exec origin bash -c "oc get services" | awk '{if ( $1 == "docker-registry" ) { print $2 } }'`
if [[ -z "${REGISTRY}" ]]; then
	echo "Unable to find Registry"
	exit 1
fi
sudo docker tag debian:latest ${REGISTRY}:5000/mch/debian:latest
sudo docker login -u mchudgins@dstsystems.com -e mchudgins@dstsystems.com -p `oc whoami -t` ${REGISTRY}:5000
sudo docker push ${REGISTRY}:5000/mch/debian:latest
oc new-app --file generic-template.json -p IMAGESTREAM=golang,CONTEXT_DIR=/golang,GIT_REF=master,GIT_URI=https://github.com/mchudgins/openshift-builders.git,BASE_IMAGESTREAM=debian:latest
oc start-build bc/golang
oc logs --follow golang-1-build
