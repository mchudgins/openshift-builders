#
# This container packages the baseline java 1.8 jre
#

FROM		debian:latest
MAINTAINER	Mike Hudgins <mchudgins@dstsystems.com> @mchudgins

LABEL io.k8s.description="Java JRE v1.8" \
      io.k8s.display-name="Java JRE v1.8" \
      io.openshift.tags="java"

RUN yum install -y ca-certificates curl java-1.8.0-openjdk \
	&& yum clean all


