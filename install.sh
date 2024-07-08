#!/bin/bash

running_dockers=$(cat .env | grep RUNNING_DOCKERS | awk -F '=' '{print $2}')

if [ "$running_dockers" != "" ]; then
	docker-compose up -d $running_dockers
fi

if [ -d shuffle-database ]; then
	chown -R 1000:1000 shuffle-database
fi	
