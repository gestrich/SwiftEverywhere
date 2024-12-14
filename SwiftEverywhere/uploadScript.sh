#!/bin/bash

# Fetch the public IP address
ipAddress=$(curl -4 -s ifconfig.me)

# Get the current Unix timestamp
uploadDate=$(date +%s)

# Construct the JSON payload
payload=$(cat <<EOF
{
	"ipAddress": "$ipAddress",
	"uploadDate": $uploadDate
}
EOF
)

# Send the POST request with curl
curl -X POST http://localhost:8080/updateHost \
  -H "Content-Type: application/json" \
  -d "$payload"
