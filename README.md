# keycloak-mtls

An example of Keycloak client mtls used to troubleshoot.  Take a look at the github discussion here https://github.com/keycloak/keycloak/discussions/15580#discussioncomment-4405291

## Generate public and private Keys ##
The directory ./certs contains the script ./makeCerts.  Run `./makeCerts.sh <ip>` to generate self signed root, server, and client keys.  The script adds the keys to a keystore and truststore that get copied to the directory ./genCerts.  The docker compose file mounts the directory in a volume to be used by keycloak.  

## Start Keycloak ##
Startup Keycloak using `docker-compose up` from the repo root.

## Import Keystore ##
Open the admin console at `http://<ip>:8443` and login with credentials admin:admin.  Thgis is done by clicking on the master drop down and clicking the Create Realm button.  Use the exported realm x509-realm-export.json to setup the realm and configure it to do a x509 login.

Navigate to `https://<host ip>:8443/realms/x509/account/`

