#!/bin/sh
# Based on:
# https://gist.github.com/polevaultweb/c83ac276f51a523a80d8e7f9a61afad0
# https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/

set -euo pipefail

# Parse options, ugly hack, I know.
# From https://unix.stackexchange.com/a/353639
CA_NAME=""
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            CA_NAME)              CA_NAME=${VALUE} ;;
            *)
    esac


done

# Validate we have a name
if [ -z "$CA_NAME" ]
then
      echo "Provide CA name with CA_NAME argument, do NOT include 'CA' in the actual name."
      exit;
fi

# Create a folder and move into it.
# Using a prefix, to easily gitignore.
CA_FOLDER_NAME="ca-$CA_NAME"
mkdir "$CA_FOLDER_NAME"
cd "$CA_FOLDER_NAME"

# This has to be kept in sync with the create-self-signed-cert.sh script.
CA_KEY_FILE_NAME="$CA_NAME-ca-private-key".key
CA_KEY_LENGTH=4096
CA_CERT_DAYS=1825
CA_CERT_FILE_NAME="$CA_NAME-ca-root-cert".pem

# TODO: These could use some escaping to ensure the subject string is well formatted
CA_CERT_O="SC - custom CA"
CA_CERT_OU="Much Secure WOW"
CA_CERT_CN="much.secure.wow - $CA_NAME"
CA_CERT_SUBJ="/C=US/ST=Texas/L=Dallas/O=$CA_CERT_O/OU=$CA_CERT_OU/CN=$CA_CERT_CN"

# Do the heavy work
echo "Generating CA private key"
echo "!!!!!!!!!!!!! Ensure pass phrase is in password manager !!!!!!!!!!!!!"
openssl genrsa -aes256 -out "$CA_KEY_FILE_NAME" $CA_KEY_LENGTH
chmod 600 "$CA_KEY_FILE_NAME"
echo "Generating CA root certificate"
openssl req -x509 -new -nodes \
  -subj "$CA_CERT_SUBJ" \
  -key "$CA_KEY_FILE_NAME" -sha256 -days $CA_CERT_DAYS -out "$CA_CERT_FILE_NAME"

echo "!!!!!!!!!!!!! Must trust the $CA_FOLDER_NAME/$CA_CERT_FILE_NAME in all devices !!!!!!!!!!!!!"

