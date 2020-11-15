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
    - iPhone:
        1. Email cert, open it.
        2. Go to General > Profile > Install the cert
        3. Go to General > About > Certificate Trust Settings and enable the cert

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
    - If no custom DNS resolver (e.g. through Pi-hole, you can use the local 'hosts' file)
1. Using the steps above, generate a PKCS12 file and have the password for it
2. Move the PKCS12 file to a location readable by the container
3. On Plex go to > Settings > Network
4. Enter file path in 'Custom certificate location'
5. Enter PKCS12 password
6. On 'Custom certificate domain' enter domain & port. e.g. `plex.synology.local:32400`
7. On 'Custom server access URLs' enter full URL. e.g. `https://plex.synology.local:32400/web/`
    - If you don't do this, connections will use a default `*.plex.direct` cert.
8. Restart Plex (or container).

## Setting up on Pi-hole (assuming via Docker)
0. Taken from: https://discourse.pi-hole.net/t/enabling-https-for-your-pi-hole-web-interface/5771 & from Synology can
 enter console running command 'bash' from Synology interface.
1. Define the hostname, ensure there is DNS for it and cert matches hostname
    - If no custom DNS resolver (e.g. through Pi-hole, you can use the local 'hosts' file)
2. Save in a file called external.conf, remember to update domain
```
$HTTP["host"] == "pi-hole.synology.local" {
  # Ensure the Pi-hole Block Page knows that this is not a blocked domain
  setenv.add-environment = ("fqdn" => "true")

  # Enable the SSL engine with a LE cert, only for this specific host
  $SERVER["socket"] == ":443" {
    ssl.engine = "enable"
    ssl.pemfile = "/custom-cert/cert-with-key.pem"

    ssl.honor-cipher-order = "enable"
    ssl.cipher-list = "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH"
    ssl.use-sslv2 = "disable"
    ssl.use-sslv3 = "disable"
  }

  # Redirect HTTP to HTTPS
  $HTTP["scheme"] == "http" {
    $HTTP["host"] =~ ".*" {
      url.redirect = (".*" => "https://%0$0")
    }
  }
}
```
2. Mount the cert & private key file (PEM), so it can be readable by the container and matches the path and name defined
 in `ssl.pemfile`

## Setting up on Synology
1. Define a hostname & domain (full FQDN). e.g. `main-a.synology.local`
2. Create a certificate using steps above for the FQDN.
3. Import using the wizard from Settings > Security, configure it for all services.