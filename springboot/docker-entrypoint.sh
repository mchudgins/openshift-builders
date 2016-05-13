#!/bin/bash
#set -e

if [[ "$1" = 'runapp' ]]; then

	#
	# create the client cert file from the cert + key
	#
#	cp /etc/apache2/certs/cert.crt /etc/apache2/certs/client.pem
#	sed 's/PRIVATE KEY/RSA PRIVATE KEY/g' /etc/apache2/keys/cert.key >>/etc/apache2/certs/client.pem

	#
	# create server cert file from the cert + bundle
	#
#	cp /etc/apache2/certs/cert.crt /etc/apache2/certs/server.pem
#	cat /etc/apache2/certs/bundle.crt >>/etc/apache2/certs/server.pem

	#
	# create the accepted CA file
	#
#	cp /usr/local/share/ca-certificates/dst-root-ca.crt /etc/apache2/certs/accepted-proxy-ca-bundle.pem

	if [[ -z "${JAVA_FLAGS}" ]]; then
		JAVA_FLAGS=-Djava.security.egd=file:/dev/./urandom
	fi

	echo "exec java ${APPFLAGS} -jar /app.jar (`cat /artifact.id`)"
	exec java ${JAVA_FLAGS} -jar /app.jar ${APP_FLAGS}
fi

exec "$@"
