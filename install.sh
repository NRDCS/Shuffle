#!/bin/bash

running_dockers=$(cat .env | grep RUNNING_DOCKERS | awk -F '=' '{print $2}')

if [ "$running_dockers" != "" ]; then
	docker-compose up -d $running_dockers
fi

#changing shuffle-database directory owner and setting max_map_count for opensearch
if [ -d shuffle-database ]; then
	if [[ "$running_dockers" == *"opensearch"* ]] && [[ "$running_dockers" == *"backend"* ]]; then
		sysctl -w vm.max_map_count=262144
		chown -R 1000:1000 shuffle-database
		#checking when opensearch will be up
		db_status=$(nc -v -w1 127.0.0.1 9200 2>&1)
		while true; do
			echo "waiting when opensearch will be up"
			db_status=$(nc -v -w1 127.0.0.1 9200 2>&1)
			if [[ "$db_status" == *"succeeded"* ]]; then
				docker restart shuffle-opensearch
				#after restarting opensearch waiting when it will be up
				while true; do
					echo "restarted opensearch waiting when it will be up"
					db_status=$(nc -v -w1 127.0.0.1 9200 2>&1)
					if [[ "$db_status" == *"succeeded"* ]]; then
						break;
					fi
					sleep 1;
				done
				break;
			fi
			sleep 1;
		done
		#when opensearch is up, checking if backend listens on 5001 TCP port, if not- restarting backend
		backend_status=$(nc -v -w1 127.0.0.1 5001 2>&1)
		if [[ "$db_status" == *"succeeded"* ]] && [[ "$backend_status" != *"succeeded"* ]]; then
			docker restart shuffle-backend
		fi
	fi
fi
