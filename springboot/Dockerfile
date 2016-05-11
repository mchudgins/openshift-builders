#
# This container packages a springboot jar
#

FROM		debian:latest
MAINTAINER	Mike Hudgins <mchudgins@dstsystems.com> @mchudgins

LABEL io.k8s.description="A springboot builder" \
      io.k8s.display-name="Springboot Builder" \
      io.openshift.tags="springboot"

ENV ARTIFACT_URL http://artifacts-scm.dstcorp.net/artifactory/horizon-libs-snapshot-local/com/dstsystems/horizon/Horizon-Batch/0.0.2-SNAPSHOT/Horizon-Batch-0.0.2-SNAPSHOT.jar

RUN yum install -y ca-certificates curl java-1.8.0-openjdk \
	&& yum clean all

RUN	curl -sL ${ARTIFACT_URL} -o /app.jar \
	&& chmod ugo+rwx /app.jar

RUN java -version

RUN javac -version


