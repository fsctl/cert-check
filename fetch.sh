#!/bin/sh

SECURITY_CMD=$(which security)
MD5_CMD=$(which md5sum)
if [ ! -x "$MD5_CMD" ]; then
	MD5_CMD=$(which md5)
	if [ ! -x "$MD5_CMD" ]; then
		MD5_CMD="openssl dgst -md5"
	fi
fi
DATE=$(date)

echo "    ---- CONDENSED OUTPUT ----"
while read -r line; do
	SERVER_NAME=$(echo $line | sed -e 's#https://\([^/]*\).*#\1#')
	echo "=============================================================================================" >> full-out.tmp
	echo "🌐 https://$SERVER_NAME/ ($DATE)" >> full-out.tmp
	dig +short $SERVER_NAME >> full-out.tmp
	echo "=============================================================================================" >> full-out.tmp
	echo "" >> full-out.tmp
	echo "quit" | openssl s_client -no_ticket -showcerts -servername $SERVER_NAME -connect $SERVER_NAME:443 2>temp-stderr-$SERVER_NAME \
		| awk '/-----BEGIN CERTIFICATE-----/ { cert = "" } \
		       { cert = cert $0 "\n" } \
		       /-----END CERTIFICATE-----/ { \
		           openssl = "openssl x509 -text -noout -fingerprint -sha1"; \
                           print cert | openssl; \
                           close(openssl) \
		       }' > temp-stdout-$SERVER_NAME

	echo "ℹ️  Certificate Chain Summary\n" >> full-out.tmp
	cat temp-stderr-$SERVER_NAME >> full-out.tmp
	echo "" >> full-out.tmp
	echo "🔒 Full Certificate Chain\n" >> full-out.tmp
	cat temp-stdout-$SERVER_NAME >> full-out.tmp
	echo "" >> full-out.tmp

	ROOT_CA_NAME=$(head -n1 temp-stderr-$SERVER_NAME | sed -e 's#.*CN = ##')
	rm temp-stderr-$SERVER_NAME
	if [ -x "$SECURITY_CMD" ] ; then
		security find-certificate -a -p -c "$ROOT_CA_NAME" /System/Library/Keychains/SystemRootCertificates.keychain \
			| awk '/-----BEGIN CERTIFICATE-----/ { cert = "" } \
			       { cert = cert $0 "\n" } \
			       /-----END CERTIFICATE-----/ { \
			           openssl = "openssl x509 -text -noout -fingerprint -sha1"; \
			           print cert | openssl; \
			           close(openssl) \
			       }' > root-ca-temp-stdout-$SERVER_NAME
		cat root-ca-temp-stdout-$SERVER_NAME >> full-out.tmp
	else
		echo "Root CA information not available" >> full-out.tmp
	fi
	echo "" >> full-out.tmp
	echo "" >> full-out.tmp

	# Print shortest version to stdout immediately
	echo "\033[1mhttps://$SERVER_NAME/\033[0m " | tr -d '\n'
	cat temp-stdout-$SERVER_NAME | awk -f bytes-only.awk | awk -v md5="$MD5_CMD" '{ print $0 | md5; close(md5); }' | tr '\n' ' '
	if [ -x "$SECURITY_CMD" ] ; then
		cat root-ca-temp-stdout-$SERVER_NAME | awk -f bytes-only.awk | awk -v md5="$MD5_CMD" '{ print $0 | md5; close(md5); }' | tr '\n' ' '
	fi
	echo ""

	# Print short version to short-out.tmp
	echo "🌐 \033[1mhttps://$SERVER_NAME/\033[0m ($DATE)" >> short-out.tmp
	dig +short $SERVER_NAME | awk '{ print "  " $0 }' >> short-out.tmp
	echo "" >> short-out.tmp
	cat temp-stdout-$SERVER_NAME | awk -f formatter.awk >> short-out.tmp
	rm temp-stdout-$SERVER_NAME 
	if [ -x "$SECURITY_CMD" ] ; then
		cat root-ca-temp-stdout-$SERVER_NAME | awk -f formatter.awk >> short-out.tmp
		rm root-ca-temp-stdout-$SERVER_NAME
	fi
done

echo ""
echo "    ---- PARTIALLY CONDENSED OUTPUT ----"
echo ""
cat short-out.tmp
rm short-out.tmp

echo ""
echo "    ---- FULL OUTPUT ----"
echo ""
cat full-out.tmp
rm full-out.tmp
