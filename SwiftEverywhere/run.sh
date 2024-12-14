#!/bin/bash

# Define the configuration file path
CONFIG_FILE=".configuration.json"

# Check if the configuration file exists
if [[ ! -f $CONFIG_FILE ]]; then
    echo "Error: Configuration file '$CONFIG_FILE' does not exist."
    exit 1
fi

# Extract the apiGatewayURL from the configuration file
apiGatewayURL=$(jq -r '.apiGatewayURL // empty' "$CONFIG_FILE")

# Check if apiGatewayURL is set
if [[ -z "$apiGatewayURL" ]]; then
    echo "Error: 'apiGatewayURL' is missing in the configuration file."
    exit 1
fi

# Export the API_GATEWAY_URL environment variable
export API_GATEWAY_URL="$apiGatewayURL"

# Stop the existing service
echo "Stopping swift_everywhere.service..."
sudo systemctl stop swift_everywhere.service

# Run the Swift server
echo "Starting Swift server..."
swift run SEServer serve --env production --hostname "0.0.0.0" --port "8080"
