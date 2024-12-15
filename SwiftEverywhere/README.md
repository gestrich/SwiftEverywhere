# SwiftEverywhereLambda

## Background

Raspberry Pi, iOS App, AWS Lambda, all written in Swift

# Lambda

* sam build;
* sam deploy;
* After deploy, add your Raspberry pi url to Secrets manager for "pi-url"




# Raspberry Pi

Pi Model: Raspberry Pi 4 Model B Rev 1.4
Memory: 256GB mini-SD card. I originally used an 8GB card but it as not enough for installing Swift.
OS: Raspberry Pi OS (64-bit), from [Raspberry Pi Imager](https://www.raspberrypi.com/software)

When you reach the option to set "customizations":

## Run on Pi

* Download Visual Studio Code
* Install the Microsoft Remote - SSH to run on Pi from Mac

nohup swift run > output.log 2>&1 &

##  Run Vapor App on Startup

sudo vi /etc/systemd/system/swift_everywhere.service

```
[Unit]
Description=Swift Everywhere Service
After=network.target

[Service]
ExecStart=/usr/bin/bash run.sh runPi
StandardOutput=journal
StandardError=journal
Environment="LC_ALL=C.UTF-8"
WorkingDirectory=/home/bill/SwiftEverywhere/SwiftEverywhere
Restart=always
User=bill

[Install]
WantedBy=multi-user.target
```

### Reload systemd to Recognize the New Service
sudo systemctl daemon-reload

### Start the Service
sudo systemctl start swift_everywhere.service

### Enable the Service to Run on Boot

sudo systemctl enable swift_everywhere.service

### Get Status

sudo systemctl status swift_everywhere.service

### Stop and Restart the Service

sudo systemctl stop swift_everywhere.service
sudo systemctl restart swift_everywhere.service

### Log Output

sudo journalctl -u swift_everywhere.service

## Upload IP Address hourly

Create a new service file for uploadScript.sh:
```
sudo vi /etc/systemd/system/uploadScript.service
```
Add the following:

```
[Unit]
Description=Upload host information every hour
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/bash run.sh postHost
WorkingDirectory=/home/bill/SwiftEverywhere/SwiftEverywhere
User=bill

[Install]
WantedBy=multi-user.target
```

Create a timer file to run the script hourly:

```
sudo vi /etc/systemd/system/uploadScript.timer
```

```
[Unit]
Description=Timer to run uploadScript.service every hour

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
```

Reload systemd to recognize the new service and timer:

```
sudo systemctl daemon-reload
```
Enable the timer to start at boot:
```
sudo systemctl enable uploadScript.timer
```
Start the timer:
```
sudo systemctl start uploadScript.timer 
```

### Setup Remote Login

You will want to avoid typing in your password for every login.

From your client (mac)

* ssh-keygen -t rsa
* When prompted enter file name:  /Users/bill/.ssh/id_rsa_raspberry_pi
* ssh-copy-id -f -i /Users/bill/.ssh/id_rsa_raspberry_pi.pub -p <port> <username>@<ip address>

For Pi on your local network:
```
Host <Raspberry Pi IP adderess>
    HostName <Raspberry Pi IP adderess> 
    User <UserName>
    IdentityFile /Users/bill/.ssh/id_rsa_raspberry_pi
```
For Pi accessible via Port Forwarding:
```
Host <Router IP Address> 
    HostName <Router IP Address>
    Port <Port>
    User <Username>
    IdentityFile /Users/bill/.ssh/id_rsa_raspberry_pi

```

On host (Raspberry Pi)

* chmod 700 ~/.ssh
* chmod 600 ~/.ssh/authorized_keys
* vi ~/.ssh/config

# Vapor App

### Port Forwarding

This is out of the scope of this guide but your api endpoint will look like:

http://<ip address>:<port>

### Setup configuration

sudo apt-get install jq
Add a .configuration file to SwiftEverywhere package directory with the following:
{
    "apiGatewayURL": "https://<api gw url>"
}

### Running

./run.sh
