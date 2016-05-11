#
# This container packages a springboot jar
#

FROM		debian:latest
MAINTAINER	Mike Hudgins <mchudgins@dstsystems.com> @mchudgins

LABEL io.k8s.description="A springboot builder" \
      io.k8s.display-name="Springboot Builder" \
      io.openshift.tags="springboot"

ENV APPFLAGS -Djava.security.egd=file:/dev/./urandom
ENV ARTIFACT_URI

RUN yum install -y ca-certificates curl java-1.8.0-openjdk \
	&& yum clean all

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]

CMD [ "runapp" ]

COPY docker-entrypoint.sh /entrypoint.sh

RUN	echo ${ARTIFACT_URL} > /artifact.id \
	&& curl -sL ${ARTIFACT_URL} -o /app.jar \
	&& chmod ugo+rx /app.jar


