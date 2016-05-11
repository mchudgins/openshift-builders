#
# This container packages a springboot jar
#

# behavior of the build depends on two ENV variables:
#	ARTIFACT_URI -- the URL from which to download the springboot jar
#	APPFLAGS -- defines the flags passed to the springboot jar when launched
#

FROM		debian:latest
MAINTAINER	Mike Hudgins <mchudgins@dstsystems.com> @mchudgins

LABEL io.k8s.description="A springboot builder" \
      io.k8s.display-name="Springboot Builder" \
      io.openshift.tags="springboot"

RUN yum install -y ca-certificates curl java-1.8.0-openjdk \
	&& yum clean all

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]

CMD [ "runapp" ]

COPY docker-entrypoint.sh /entrypoint.sh

RUN	echo ${ARTIFACT_URI} > /artifact.id \
	&& curl -sL ${ARTIFACT_URI} -o /app.jar \
	&& chmod ugo+rx /app.jar


