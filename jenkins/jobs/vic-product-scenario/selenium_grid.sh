#!/bin/bash
# Copyright 2018 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
set -x

start_node () {
    docker run -d --net ${NETWORK} -e HUB_HOST=${HUB_NM} -v /dev/shm:/dev/shm --name "$1" "$2"

    for _ in $(seq 1 10); do
        if [[ "$(docker logs "$1")" = *"The node is registered to the hub and ready to use"* ]]; then
            echo "$1 node is up and ready to use";
            return 0;
        fi
        sleep 3;
    done
}

remove_all () {
    echo "Kill any old selenium infrastructure..."
    docker rm -f ${HUB_NM} ${NODE1_NM} ${NODE2_NM} ${NODE3_NM} ${NODE4_NM}
    docker network prune -f
}

if [ $# -ne 2 ] ; then
    echo "Usage: $0 create/remove suffix"
    exit 1
fi

ACTION=$1
SUFFIX=$2
NETWORK="grid-${SUFFIX}"
HUB_NM="selenium-hub-${SUFFIX}"
NODE1_NM="firefox1-${SUFFIX}"
NODE2_NM="firefox2-${SUFFIX}"
NODE3_NM="firefox3-${SUFFIX}"
NODE4_NM="firefox4-${SUFFIX}"

case ${ACTION} in
    create)
        remove_all
        echo "Create the network, hub and workers..."
        docker network create ${NETWORK}
        docker run -d --net ${NETWORK} --name ${HUB_NM} selenium/hub:3.9.1
        for _ in $(seq 1 10); do
            if [[ "$(docker logs ${HUB_NM} 2>&1)" = *"Selenium Grid hub is up and running"* ]]; then
                echo 'Selenium Server is up and running';
                break
            fi
            sleep 3;
        done

        start_node ${NODE1_NM} selenium/node-firefox:3.9.1
        start_node ${NODE2_NM} selenium/node-firefox:3.9.1
        start_node ${NODE3_NM} selenium/node-firefox:3.9.1
        start_node ${NODE4_NM} selenium/node-firefox:3.9.1
        ;;
    remove)
        remove_all
        ;;
    *)
        echo "${ACTION} is not supported."
        exit 1
        ;;
esac

