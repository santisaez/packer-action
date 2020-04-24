#!/usr/bin/env bash

set -e -o pipefail -u

# Set default variables
: "${INPUT_SECRET:=}"
: "${INPUT_OPTIONS:=--}" # a double dash means the end of command options

# Set and export default variables
export SECRET_FILE="${SECRET_FILE:=/tmp/packer-secret}"

# fatal creates an error annotation and aborts the program execution
function fatal() {
	local error_msg=$1
	echo "::error::${error_msg}"
	exit 1
}

function cleanup() {
	if [ -f "${SECRET_FILE}" ] ; then
		shred -u -f "${SECRET_FILE}"
	fi
}

trap "cleanup" EXIT

if [ -n "${INPUT_SECRET}" ] ; then
	# Set a temporary mask using a subshell to write the secret to a read-only file
	(umask 0266 && echo "${INPUT_SECRET}" > "${SECRET_FILE}")

	# Remove env variable once the secret is written
	unset INPUT_SECRET
fi

if [ -z "${INPUT_TEMPLATE}" ] ; then
	fatal "'template' input parameter not provided"
fi

if ! packer validate -only="${INPUT_ONLY:=}" "${INPUT_OPTIONS}" "${INPUT_TEMPLATE}" ; then
	fatal "'${INPUT_TEMPLATE}' template validation failed"
fi

if ! packer build -timestamp-ui -only="${INPUT_ONLY:=}" "${INPUT_OPTIONS}" "${INPUT_TEMPLATE}" ; then
	fatal "'${INPUT_TEMPLATE}' build failed"
fi
