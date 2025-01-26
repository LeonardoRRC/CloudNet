#!/bin/bash

cd /home/container || exit 1

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET_COLOR='\033[0m'

# Print Installed Java version
echo -e "${CYAN}========================================="
echo -e "   Available Java Versions"
echo -e "=========================================${RESET_COLOR}"

# Get and list available Java versions
update-alternatives --list java | while read -r java_path; do
    java_version=$($java_path -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo -e "${GREEN}Java Version:${RESET_COLOR} ${YELLOW}$java_version${RESET_COLOR}  →  ${java_path}"
done

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

echo -e "${CYAN}The Internal IP is ${INTERNAL_IP}"

# Edit CloudNet's Downloaded Config.json
if [ -e config.json ]
then
    echo -e "CloudNet Identify Host Adress set to ${INTERNAL_IP}"
    jq ".identity.listeners[0].host = \"${INTERNAL_IP}\"" config.json > config.json.tmp
    mv config.json.tmp config.json

    echo -e "CloudNet Port Set ${CLOUDNET_PORT}"
    jq ".identity.listeners[0].port = \"${CLOUDNET_PORT}\"" config.json > config.json.tmp
    mv config.json.tmp config.json

    echo -e "HttpListener set to to 0.0.0.0"
    jq ".httpListeners[0].host = \"0.0.0.0\"" config.json > config.json.tmp
    mv config.json.tmp config.json

    echo -e "HttpListener WebServer port set to ${CLOUDNET_WEBSERVER}"
    jq ".httpListeners[0].port = \"${CLOUDNET_WEBSERVER}\"" config.json > config.json.tmp
    mv config.json.tmp config.json

    echo -e "CloudNet Host Adress set to ${INTERNAL_IP}"
    jq ".hostAddress = \"${INTERNAL_IP}\"" config.json > config.json.tmp
    mv config.json.tmp config.json

    echo -e "Added Container ID to whitelist ${P_SERVER_UUID}"
    jq ".ipWhitelist[0] = \"${P_SERVER_UUID}\"" config.json > config.json.tmp
    mv config.json.tmp config.json

    echo -e "Added Docker network IP to whitelist ${INTERNAL_IP}"
    jq ".ipWhitelist[1] = \"${INTERNAL_IP}\"" config.json > config.json.tmp
    mv config.json.tmp config.json

    echo -e "Max Ram set to: ${SERVER_MEMORY}"
    jq ".maxMemory= \"${SERVER_MEMORY}\"" config.json > config.json.tmp
    mv config.json.tmp config.json
else
    echo -e "${CYAN}config.json not exist"
fi

# Replace Startup Variables
# shellcheck disable=SC2086
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e "${CYAN}/home/container: ${MODIFIED_STARTUP} ${RESET_COLOR}"

# Run the Server
# shellcheck disable=SC2086
eval ${MODIFIED_STARTUP}
