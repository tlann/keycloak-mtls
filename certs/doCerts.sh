#!/usr/bin/env sh

#Lovingly copies from https://developers.redhat.com/blog/2021/02/19/x-509-user-certificate-authentication-with-red-hats-single-sign-on-technology#step_2__create_user_certificates

PASSWORD="changeit"

echo "Create a local certificate authority"

openssl genrsa -aes256 -passout pass:$PASSWORD -out ca.pass.key 4096
openssl rsa -passin pass:$PASSWORD -in ca.pass.key -out ca.key
openssl req -new -x509 -days 3650 -key ca.key -out ca.pem

CLIENT_ID="user1"
CLIENT_SERIAL=01


echo "Generate a user private key"
openssl genrsa -aes256 -passout pass:$PASSWORD -out ${CLIENT_ID}.pass.key 4096
openssl rsa -passin pass:$PASSWORD -in ${CLIENT_ID}.pass.key -out ${CLIENT_ID}.key


echo "Generate a user-signed certificate request"
openssl req -new -key ${CLIENT_ID}.key -out ${CLIENT_ID}.csr

echo "Generate a user-signed request signed by the CA (public certificate)"
openssl x509 -req -days 3650 -in ${CLIENT_ID}.csr -CA ca.pem -CAkey ca.key -set_serial ${CLIENT_SERIAL} -out ${CLIENT_ID}.pem

echo "Generate a PFX user certificate and upload it to Chrome"
openssl pkcs12 -export -out ${CLIENT_ID}.pfx -inkey ${CLIENT_ID}.key -in ${CLIENT_ID}.pem

echo "Create a keystore using keytool"
keytool -genkey -alias localhost -keyalg RSA -keystore keystore.jks -validity 10950

echo "Create a truststore using keytool"
keytool -import -alias HOSTDOMAIN -keystore truststore.jks -file ca.pem

mkdir ../genCerts
cp *.jks ../genCerts

