#!/bin/bash

# Function to kill existing server instance on a given port
kill_existing_server() {
    local port=$1
    echo "Killing existing server instance on port $port, if any..."
    lsof -i :$port | awk '{if(NR>1) system("kill -9 " $2)}'
}

# Function to run the Swift server
run_pi() {
    # Define the configuration file path
    CONFIG_FILE=".configuration.json"

    # Check if the configuration file exists
    if [[ ! -f $CONFIG_FILE ]]; then
        echo "Error: Configuration file '$CONFIG_FILE' does not exist."
        exit 1
    fi

    # Extract the apiGatewayURL and port from the configuration file
    apiGatewayURL=$(jq -r '.apiGatewayURL // empty' "$CONFIG_FILE")
    port=$(jq -r '.port // empty' "$CONFIG_FILE")

    # Check if apiGatewayURL and port are set
    if [[ -z "$apiGatewayURL" ]]; then
        echo "Error: 'apiGatewayURL' is missing in the configuration file."
        exit 1
    fi

    # Kill existing server instance on the specified port
    kill_existing_server "$port"

    # Export the API_GATEWAY_URL environment variable
    export API_GATEWAY_URL="$apiGatewayURL"

    # Run SEPi server
    echo "Starting Swift server on port $port..."
    swift run SEPi serve --env production --hostname "0.0.0.0" --port 8080 
}

# Function to upload the host details
upload_host() {
    # Define the configuration file path
    CONFIG_FILE=".configuration.json"

    # Check if the configuration file exists
    if [[ ! -f $CONFIG_FILE ]]; then
        echo "Error: Configuration file '$CONFIG_FILE' does not exist."
        exit 1
    fi

    # Extract the port from the configuration file
    port=$(jq -r '.port // empty' "$CONFIG_FILE")

    # Check if port is set
    if [[ -z "$port" ]]; then
        echo "Error: 'port' is missing in the configuration file."
        exit 1
    fi

    # Fetch the public IP address
    ipAddress=$(curl -4 -s ifconfig.me)

    # Get the current Unix timestamp
    uploadDate=$(date +%s)

    # Construct the JSON payload
    payload=$(cat <<EOF
{
    "ipAddress": "$ipAddress",
    "port": $port,
    "uploadDate": $uploadDate
}
EOF
    )

    # Send the POST request with curl
    echo "Uploading host details to the server on port $port..."
    curl -X POST http://localhost:$port/updateHost \
        -H "Content-Type: application/json" \
        -d "$payload"
}

# Main script execution based on the argument
case "$1" in
    runPi)
        run_pi
        ;;
    uploadHost)
        upload_host
        ;;
    *)
        echo "Usage: $0 {runPi|uploadHost}"
        exit 1
        ;;
esac
