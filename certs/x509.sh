#!/bin/bash

#lovingly inspired from https://gist.github.com/dasniko/b1aa115fd9078372b03c7a9f7e9ec189

PW=changeit

echo "*********"
echo "RootCA"
echo "*********"
openssl req -x509  -passin pass:$PW -sha256 -days 3650 -newkey rsa:4096 -keyout rootCA.key -out rootCA.crt 

echo "*********"
echo "Host certificate csr"
echo "*********"
openssl req -new -newkey rsa:4096  -passin pass:$PW -keyout localhost.key -out localhost.csr -nodes 

echo "*********"
echo "Sign host csr with rootCA (see below for file localhost.ext):"
echo "*********"
openssl x509 -req  -passin pass:$PW -CA rootCA.crt -CAkey rootCA.key -in localhost.csr -out localhost.crt -days 365 -CAcreateserial -extfile localhost.ext

echo "*********"
echo "Create pkcs12 file for server "
echo "*********"
openssl pkcs12 -export -in localhost.crt -inkey localhost.key -out keystore.p12 -name "server certificate" -chain -CAfile rootCA.crt -caname "self signed ca certificate" -passin pass:$PW -passout pass:$PW

echo "*********"
echo "Client (user) certificate"
echo "*********"
openssl req -new -newkey rsa:4096 -nodes -keyout fredFlintstone.key -out fredFlintstone.csr

echo "*********"
echo "Sign client csr with rootCA:"
echo "*********"
openssl x509 -req -CA rootCA.crt -CAkey rootCA.key -in fredFlintstone.csr -out fredFlintstone.crt -days 365 -CAcreateserial

echo "*********"
echo "Import client key and crt in keystore to create the certificate to be used in the browser:"
echo "*********"
openssl pkcs12 -export -out fredFlintstone.p12 -name "fredFlintstone" -inkey fredFlintstone.key -in fredFlintstone.crt

echo "*********"
echo "Create a keystore using keytool"
echo "*********"

keytool -importkeystore -destkeystore keystore.jks -srckeystore keystore.p12 -srcstoretype PKCS12 -alias "server certificate" -srcstorepass $PW -deststorepass $PW

echo "*********"
echo "Create a truststore using keytool"
echo "*********"
keytool -importcert -alias HOSTDOMAIN -keystore truststore.jks -file rootCA.crt


mkdir ../genCerts
cp *.jks ../genCerts
