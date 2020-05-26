#!/bin/sh

REGION=eu-west-1
REPO=444836393510.dkr.ecr.eu-west-1.amazonaws.com

aws ecr get-login-password --region ${REGION} | \
    docker login --username AWS --password-stdin ${REPO}


for image in elasticsearch logstash filebeat apache; do
    # make sure the repository exists:
    exists=$(aws ecr describe-repositories | \
		 jq .repositories[].repositoryName | grep ${image})
    if [ -z "${exists}" ]; then
	aws ecr create-repository --repository-name ${image}
    fi

    # build and upload the images
    docker build -t ${image} images/${image} \
	   --build-arg VERSION=7.7.0 \
           --build-arg REGION=${REGION}
    docker tag ${image}:latest ${REPO}/${image}:latest
    docker push ${REPO}/${image}:latest
done
