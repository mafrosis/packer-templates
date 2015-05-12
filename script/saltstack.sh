#!/bin/bash -eux

SALT_VERSION=${SALT_VERSION:-latest}
if [[ $DEBUG =~ true ]]; then
	BOOTSTRAP_OPTIONS='-D -K'
fi

if [[ -z $(which curl) ]]; then
	sudo apt-get install -y curl
fi

if [[ ${SALT_VERSION:-} == 'latest' ]]; then
  echo "==> Installing latest Salt version"
  curl -L https://raw.githubusercontent.com/mafrosis/salt-bootstrap/jessie-debug/bootstrap-salt.sh | sudo sh
else
  echo "==> Installing Salt version ${SALT_VERSION}"
  curl -L https://raw.githubusercontent.com/mafrosis/salt-bootstrap/jessie-debug/bootstrap-salt.sh | sudo sh -s -- ${BOOTSTRAP_OPTIONS} git ${SALT_VERSION}
fi
