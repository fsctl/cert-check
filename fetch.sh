#!/bin/sh

while read -r line; do
	SERVER_NAME=$(echo $line | sed -e 's#https://\([^/]*\).*#\1#')
	echo "============================================================================================="
	echo "🌐 https://$SERVER_NAME/ ($(date))"
	dig +short $SERVER_NAME
	echo "============================================================================================="
	echo ""
	echo "quit" | openssl s_client -no_ticket -showcerts -servername $SERVER_NAME -connect $SERVER_NAME:443 2>temp-stderr-$SERVER_NAME \
		| awk '/-----BEGIN CERTIFICATE-----/ { cert = "" } \
		       { cert = cert $0 "\n" } \
		       /-----END CERTIFICATE-----/ { \
		           openssl = "openssl x509 -text -noout -fingerprint -sha1"; \
                           print cert | openssl; \
                           close(openssl) \
		       }' > temp-stdout-$SERVER_NAME

	echo "ℹ️  Certificate Chain Summary\n"
	cat temp-stderr-$SERVER_NAME
	echo ""
	echo "🔒 Full Certificate Chain\n"
	cat temp-stdout-$SERVER_NAME
	rm temp-stdout-$SERVER_NAME
	echo ""

	ROOT_CA_NAME=$(head -n1 temp-stderr-$SERVER_NAME | sed -e 's#.*CN = ##')
	rm temp-stderr-$SERVER_NAME
	security find-certificate -a -p -c "$ROOT_CA_NAME" /System/Library/Keychains/SystemRootCertificates.keychain \
		| awk '/-----BEGIN CERTIFICATE-----/ { cert = "" } \
		       { cert = cert $0 "\n" } \
		       /-----END CERTIFICATE-----/ { \
		           openssl = "openssl x509 -text -noout -fingerprint -sha1"; \
		           print cert | openssl; \
		           close(openssl) \
		       }'

	echo ""
	echo ""
done
