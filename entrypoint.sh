#!/bin/sh

set -eu

VALID_DAYS=${VALID_DAYS:-3650}
OVERWRITE=${OVERWRITE:-false}
CA=${CA:-false}
CLIENT=${CLIENT:-false}
SERVER=${SERVER:-false}

if [ "${CA}" = true ]; then
	CA_SUBJECT=${CA_SUBJECT:-"/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=docker"}
	if [ ! -f ca/ca-key.pem ] || [ "${OVERWRITE}" = true ]; then
		echo "create ca-key.pem"
		openssl genrsa -out ca/ca-key.pem 4096
	fi

	if [ ! -f ca/ca.pem ] || [ "${OVERWRITE}" = true ]; then
		echo "create ca.pem"
		openssl req -new -x509 -days $VALID_DAYS -subj "$CA_SUBJECT" -key ca/ca-key.pem -sha256 -out ca/ca.pem
	fi
fi

if [ "${CLIENT}" = true ]; then
	if [ ! -f client/client-key.pem ] || [ "${OVERWRITE}" = true ]; then
		echo "create client-key.pem"
		openssl genrsa -out client/client-key.pem 4096
	fi

	if [ ! -f client/client-cert.pem ] || [ "${OVERWRITE}" = true ]; then
		echo "create client-cert.pem"
		openssl req -subj '/CN=client' -new -key client/client-key.pem -out scratch/client.csr
		echo "extendedKeyUsage = clientAuth" > scratch/client-extfile.cnf

		openssl x509 -req -days $VALID_DAYS -sha256 -in scratch/client.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out client/client-cert.pem -extfile scratch/client-extfile.cnf
	fi
fi

if [ "${SERVER}" = true ]; then
	if [ ! -f server/server-key.pem ] || [ "${OVERWRITE}" = true ]; then
		echo "create server-key.pem"
		openssl genrsa -out server/server-key.pem 4096
	fi

	if [ ! -f server/server-cert.pem ] || [ "${OVERWRITE}" = true ]; then
		echo "create server-cert.pem"
		openssl req -subj "/CN=${SERVER_CERT_CN}" -sha256 -new -key server/server-key.pem -out scratch/server.csr

		echo "extendedKeyUsage = serverAuth" > scratch/server-extfile.cnf
		if [ -n "${SERVER_SUBJ_ALT_NAMES}" ]; then
			echo "subjectAltName = ${SERVER_SUBJ_ALT_NAMES}" >> scratch/server-extfile.cnf
		fi

		openssl x509 -req -days $VALID_DAYS -sha256 -in scratch/server.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out server/server-cert.pem -extfile scratch/server-extfile.cnf
	fi
fi

