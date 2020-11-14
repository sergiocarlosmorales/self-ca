# self-ca
Scripts to manage custom certificates

## Create a CA
1. Ensure script is executable
``
chmod u=rwx create-ca.sh
``
2. Pick a name, store a passphrase in password manager
3. Run script with selected name, enter passphrase each time it is requested:
``
./create-ca.sh CA_NAME=whatever
``
4. Install generated certificate in all devices.
    - MacOS: Double click certificate, it opens Keychain Access, find the cert, open it and under Trust, select:
     Always Trust.

## Create a self-signed certificate
1. Ensure at least one CA has been generated with these steps
2. Ensure script is executable
``
chmod u=rwx create-self-signed-cert.sh
``
3. Get the name of the CA to use, and get the name of the domain to set
    - CA would exist as a folder in this directory, like: CA-whatever, the name of this CA is only 'whatever', skip
     the CA- part.
4. Run script:
``
./create-self-signed-cert.sh CA_NAME=whatever DOMAIN=loco.local
``
5. The script generates files with the cert, the private key and a PEM with both.
6. Optional: To generate a PKCS12 file from those, run:
``
openssl pkcs12 -export -in x-cert-and-private-key.pem -out cert-and-private-key.pkcs12
`` .
It will prompt for a password, which is NOT the private key passphrase, it's a password specific to the file.

## Setting up on Plex
0. This assumes Plex is reachable via a domain and not just via IP. e.g. `plex.synology.local`
1. Using the steps above, generate a PKCS12 file and have the password for it
2. Move the PKCS12 file to a location readable by the container
3. On Plex go to > Settings > Network
4. Enter file path in 'Custom certificate location'
5. Enter PKCS12 password
6. On 'Custom certificate domain' enter domain & port. e.g. `plex.synology.local:32400`
7. On 'Custom server access URLs' enter full URL. e.g. `https://plex.synology.local:32400/web/`
    - If you don't do this, connections will use a default `*.plex.direct` cert.
8. Restart Plex (o container).