#!/bin/bash

# Variables
JSON_FILE="apns-auth-key-config.json"  # Path to the JSON file
REGION="us-east-1"                    # AWS region for the SNS platform application

# Function to prompt user for input
request_data() {
    echo "Enter the Apple Team ID (from your Apple Developer account):"
    read -r APPLE_TEAM_ID

    echo "Enter the Apple Key ID (from your Apple Developer portal):"
    read -r APPLE_KEY_ID

    echo "Enter the Apple Bundle ID (e.g., com.example.app):"
    read -r APPLE_BUNDLE_ID

    echo "Enter the path to the APNs authentication key (.p8 file):"
    read -r KEY_PATH
    if [ ! -f "$KEY_PATH" ]; then
        echo "Error: Authentication key file not found at $KEY_PATH"
        exit 1
    fi
}

# Function to save the JSON file
save_json() {
    jq -n --arg keyId "$APPLE_KEY_ID" \
          --arg teamId "$APPLE_TEAM_ID" \
          --arg bundleId "$APPLE_BUNDLE_ID" \
          --arg authKey "$(cat "$KEY_PATH")" \
    '{
        AppleKeyId: $keyId,
        AppleTeamId: $teamId,
        AppleBundleId: $bundleId,
        APNsAuthKey: $authKey
    }' > "$JSON_FILE"

    echo "Data saved to $JSON_FILE"
}

# Main logic
if [ ! -f "$JSON_FILE" ]; then
    echo "JSON file '$JSON_FILE' not found. Let's create it."
    request_data
    save_json
else
    echo "Using existing JSON file: $JSON_FILE"
fi

# Parse JSON file for required values
APPLE_KEY_ID=$(jq -r '.AppleKeyId' "$JSON_FILE")
APPLE_TEAM_ID=$(jq -r '.AppleTeamId' "$JSON_FILE")
APPLE_BUNDLE_ID=$(jq -r '.AppleBundleId' "$JSON_FILE")
APNS_AUTH_KEY=$(jq -r '.APNsAuthKey' "$JSON_FILE")

# Check if all required fields are present
if [ -z "$APPLE_KEY_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$APPLE_BUNDLE_ID" ] || [ -z "$APNS_AUTH_KEY" ]; then
    echo "Error: Missing required fields in JSON file. Please ensure all fields are populated."
    exit 1
fi

# Create the platform application
PLATFORM_ARN=$(aws sns create-platform-application \
    --name "iOSPushNotificationPlatform" \
    --platform "APNS_SANDBOX" \
    --attributes \
        PlatformPrincipal="$APPLE_KEY_ID",PlatformCredential="$APNS_AUTH_KEY",ApplePlatformTeamID="$APPLE_TEAM_ID",ApplePlatformBundleID="$APPLE_BUNDLE_ID" \
    --region "$REGION" \
    --query "PlatformApplicationArn" \
    --output text)

if [ $? -eq 0 ]; then
    echo "iOS Push Notification PlatformApplication created successfully!"
    echo "Platform Application ARN: $PLATFORM_ARN"
else
    echo "Failed to create the iOS Push Notification PlatformApplication."
    exit 1
fi

# Exit script
exit 0
