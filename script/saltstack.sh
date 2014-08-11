#!/bin/bash -eux

SALT_VERSION=${SALT_VERSION:-latest}

if [[ -z $(which curl) ]]; then
	sudo apt-get install -y curl
fi

if [[ ${SALT_VERSION:-} == 'latest' ]]; then
  echo "==> Installing latest Salt version"
  curl -L http://bootstrap.saltstack.org | sudo sh
else
  echo "==> Installing Salt version ${SALT_VERSION}"
  curl -L http://bootstrap.saltstack.org | sudo sh -s -- git ${SALT_VERSION}
fi
