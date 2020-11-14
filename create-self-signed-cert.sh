#!/bin/sh
# Based on:
# https://gist.github.com/polevaultweb/c83ac276f51a523a80d8e7f9a61afad0
# https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/

set -euo pipefail

# Parse options, ugly hack, I know.
# From https://unix.stackexchange.com/a/353639
DOMAIN=""
CA_NAME=""
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            DOMAIN)              DOMAIN=${VALUE} ;;
            CA_NAME)             CA_NAME=${VALUE} ;;
            *)
    esac


done

# Validate we have a domain
if [ -z "$DOMAIN" ]
then
      echo "Provide a domain name with DOMAIN argument"
      exit;
fi

# Validate we know which CA to use for signing
if [ -z "$CA_NAME" ]
then
      echo "Provide a CA with CA_NAME argument"
      exit;
fi

# Create a folder and move into it.
# Using a prefix, to easily gitignore.
CERT_FOLDER_NAME="cert-$DOMAIN"
CERT_CSR_FILE_NAME="$DOMAIN-certificate-signing-request".csr 
CERT_KEY_FILE_NAME="$DOMAIN".key
CERT_FILE_NAME="$DOMAIN-cert.crt"
CERT_WITH_KEY_FILE_NAME="$DOMAIN-cert-and-private-key.pem"
# Chrome and other browsers limit the max length to 1 year.
CERT_DAYS=365

# This has to be kept in sync with the create-ca.sh script.
CA_FOLDER="../ca-$CA_NAME/"
CA_CERT_FILE_PATH="$CA_FOLDER/$CA_NAME-ca-root-cert".pem
CA_KEY_FILE_PATH="$CA_FOLDER/$CA_NAME-ca-private-key".key

EXT_FILE_NAME="$DOMAIN-extensions.ext"
CERT_O="SC - custom certificate"
CERT_OU="Much Secure WOW - $CA_NAME"
CERT_SUBJ="/C=US/ST=Texas/L=Dallas/O=$CERT_O/OU=$CERT_OU/CN=$DOMAIN"

mkdir "$CERT_FOLDER_NAME"
cd "$CERT_FOLDER_NAME"


openssl genrsa -out $CERT_KEY_FILE_NAME
openssl req -new -key $CERT_KEY_FILE_NAME -out $CERT_CSR_FILE_NAME \
  -subj "$CERT_SUBJ" \

# TODO: Break this into its own script, so we have a script just to sign CSRs.
cat > $EXT_FILE_NAME << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
EOF

openssl x509 -req -in $CERT_CSR_FILE_NAME -CA "$CA_CERT_FILE_PATH" -CAkey "$CA_KEY_FILE_PATH" -CAcreateserial \
  -out $CERT_FILE_NAME -days $CERT_DAYS -sha256 -extfile "$EXT_FILE_NAME"

# Let's create a PEM file with both public & private key, some shit sometimes needs it.
touch "$CERT_WITH_KEY_FILE_NAME"
cat "$CERT_FILE_NAME" >> "$CERT_WITH_KEY_FILE_NAME"
cat "$CERT_KEY_FILE_NAME" >> "$CERT_WITH_KEY_FILE_NAME"
