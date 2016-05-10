#
# This container packages a springboot jar
#

FROM		debian:latest
MAINTAINER	Mike Hudgins <mchudgins@dstsystems.com> @mchudgins

LABEL io.k8s.description="A springboot builder" \
      io.k8s.display-name="Springboot Builder" \
      io.openshift.tags="springboot"

ENV ARTIFACT_URL http://artifacts-scm.dstcorp.net/artifactory/horizon-libs-snapshot-local/com/dstsystems/horizon/Horizon-Batch/0.0.2-SNAPSHOT/Horizon-Batch-0.0.2-SNAPSHOT.jar

RUN yum install -y ca-certificates curl \
	&& yum clean all

RUN	curl -sL https://s3.amazonaws.com/aws-cli/awscli-bundle.zip -o awscli-bundle.zip \
	&& unzip awscli-bundle.zip \
	&& ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
	&& rm awscli-bundle.zip \
	&& rm -rf awscli-bundle

RUN	curl -sL ${ARTIFACT_URL} -o /app.jar \
	&& chmod ugo+rwx /app.jar


