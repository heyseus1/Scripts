#!/bin/bash


checkroot() {
	if [ $UID -ne 0 ] ; then
		echo "User has insufficient privilege."
		exit 4
	fi
}

install_deps()
{
  apt-get -y install \
    vim \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common
}

docker_configs()
{
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
  apt-key fingerprint 0EBFCD88
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/debian \
    $(lsb_release -cs) \
    stable"
  apt-get update
  apt-get install docker-ce
}

atlassian_deploy()
{
  docker run --detach --publish 8080:8080 cptactionhank/atlassian-jira:latest
  docker run --detach --publish 8090:8090 cptactionhank/atlassian-confluence:latest
  docker run --detach --publish 8085:8085 cptactionhank/atlassian-bamboo:latest
  docker run --detach --publish 7990:7990 cptactionhank/atlassian-bitbucket:latest
}

checkroot
install_deps
docker_configs
atlassian_deploy
