#!/usr/bin/env sh

#Plagiarized from https://gist.github.com/dasniko/b1aa115fd9078372b03c7a9f7e9ec189 and other places

PW=changeit
if [ $# -eq 1 ]; then
    touch index.txt
    if [ ! -f "serial.txt" ]; then
        echo 01 > serial.txt
    fi

    #check for IP add to ser.cnf file
    sed -i "/\(DNS.2\|IP.2\).*=.*/d" openssl-server.cnf

    if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo is an IP - $1

        #add to server.cnf file
        echo "IP.2     = "$1 >> openssl-server.cnf
    fi

    #check for DNS add to server file.
    if [[ $1 =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z\-]*[A-Za-z])$\
 ]]; then
        echo is DNS  - $1
        #add to server.cnf file
        DOMAIN=${1#*.}
        #$DOMAIN=$1
        echo "Testing:" $DOMAIN
        echo "DNS.2    = *."$DOMAIN >> openssl-server.cnf
    fi


    echo "==============================================================="
    echo "Generating CA Certificate"
    echo "==============================================================="
    echo
    #private key
    openssl req -x509 -config openssl-ca.cnf -newkey rsa:2048 -sha256 -nodes -days 365 -batch -out cacert.p\
em -outform PEM -passin pass:$PW
    #public certificate
    openssl x509 -outform der -in cacert.pem -out cacert.cer -passin pass:$PW

    echo
    echo "==============================================================="
    echo "Generating and Signing Server Certificate"
    echo "==============================================================="
    echo

    openssl req -config openssl-server.cnf -newkey rsa:2048 -sha256 -nodes -days 365 -batch -out servercert\
.csr -outform PEM -passin pass:$PW
    openssl ca -batch -config openssl-ca.cnf -passin pass:$PW -policy signing_policy -extensions signing_re\
q -out server.pem -infiles servercert.csr

    echo
    echo "==============================================================="
    echo "Generating and Signing Client Certificate with CA Certificate"
    echo "==============================================================="
    echo
    #Signing request and key
    openssl req -new -config openssl-client.cnf -keyout clientKey.pem -out client.csr -passin pass:$PW
    #Sign and generate cert
    openssl x509 -req -CA cacert.pem -CAkey cakey.pem -in client.csr -out clientPub.pem -days 365 -CAcreateserial

    echo
    echo "==============================================================="
    echo "Exporting certificates to PKCS-12"
    echo "==============================================================="
    echo

    #Create pkcs-12
    openssl pkcs12 -export -in server.pem -inkey serverkey.pem -out server.p12 -name "server\
 certificate" -chain -CAfile cacert.pem -caname "ca certificate" -passin pass:$PW -passout pass:$PW
    #import ca certificate 
    keytool -import -trustcacerts -noprompt -alias "ca certificate" -file cacert.pem -keystore server.p12 -storepass $PW

    #put the client artifacts together to be imported to a client store
    cat clientKey.pem clientPub.pem > client.pem
    openssl pkcs12 -export -out client.p12 -inkey clientKey.pem -in clientPub.pem -certfile cacert.pem   -passin pass:$PW -passout pass:$PW

    echo
    echo "==============================================================="
    echo "Exporting certificates to keystore JKS"
    echo "==============================================================="
    echo

    keytool -importkeystore -destkeystore server-keystore.jks -srckeystore server.p12 -srcstoretype PKCS12\
 -alias "server certificate" -srcstorepass $PW -deststorepass $PW

    echo
    echo "==============================================================="
    echo "Exporting certificates to truststore JKS"
    echo "==============================================================="
    echo

    keytool -import -trustcacerts -noprompt -alias ca -ext san=dns:$1,ip:$1 -file cacert.cer -keystore truststore.jks -deststorepass $PW

    #Put the certs and keys in a diff directory
    mkdir -p ../genCerts
    mv *.jks ../genCerts/
    mv client.p12 ../genCerts/

    
else
    echo "Usage: makeCerts.sh ip_address"
fi




#RootCA
#openssl req -x509 -sha256 -days 3650 -newkey rsa:4096 -keyout rootCA.key -out rootCA.crt

#Host certificate
#openssl req -new -newkey rsa:4096 -keyout localhost.key -out localhost.csr -nodes

#Sign host csr with rootCA (see below for file localhost.ext):
#openssl x509 -req -CA rootCA.crt -CAkey rootCA.key -in localhost.csr -out localhost.crt -days 365 -CAcreateserial -extfile localhost.ext

#Client (user) certificate
#openssl req -new -newkey rsa:4096 -nodes -keyout fredFlintstone.key -out fredFlintstone.csr

#Sign client csr with rootCA:
#openssl x509 -req -CA rootCA.crt -CAkey rootCA.key -in fredFlintstone.csr -out fredFlintstone.crt -days 365 -CAcreateserial

#Import client key and crt in keystore to create the "certificate" to be used in the browser:
#openssl pkcs12 -export -out fredFlintstone.p12 -name "fredFlintstone" -inkey fredFlintstone.key -in fredFlintstone.crt


