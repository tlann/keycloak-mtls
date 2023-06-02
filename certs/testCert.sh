#!/bin/bash

#Script inspired from this post https://keycloak.discourse.group/t/how-to-request-access-token-with-x509-certificate-authentication-and-curl/19842

curl -XPOST https://localhost:8443/realms/x509/protocol/openid-connect/token --cacert \ 
ca.pem --data "grant_type=password&scope=openid profile&client_id=my-client&client_secret=my-client-secret&username=&password="  \
 -E user1.pem --key user1.key --header "ssl-client-cert: $(urlencode "$(cat user1.pem)")"  \
--header "ssl-client-issuer-dn: CN=Root CA"  \
--header "ssl-client-subject-dn: emailAddress=user1@example.com,CN=user1,OU=Foo,O=Bar,L=Hello,ST=Test,C=US" \
--header "ssl-client-verify: SUCCESS" -v
