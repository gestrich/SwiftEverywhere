sudo systemctl stop swift_everywhere.service
swift run SEServer serve --env production --hostname "0.0.0.0" --port "8080"
