#! /bin/bash
if [[ -z $1 ]]; then
	HOST=https://localhost:8443
else
	HOST=$1
fi
                                                                                                                                                               │ld-strategy-custom mchudgins@dstsystems.com
sudo docker pull debian:latest
oc login --insecure-skip-tls-verify ${HOST}
sudo /home/mchudgins/bin/oc --config /var/lib/origin/openshift.local.config/master/admin.kubeconfig adm policy \
	add-role-to-user system:build-strategy-custom mchudgins@dstsystems.com
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
oc new-app --file generic-template.json \
	-p IMAGESTREAM=golang \
	-p CONTEXT_DIR=/golang \
	-p GIT_REF=master \
	-p GIT_URI=https://github.com/mchudgins/openshift-builders.git \
	-p BASE_IMAGESTREAM=debian:latest
oc start-build bc/golang
oc logs --follow golang-1-build
