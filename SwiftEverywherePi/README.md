# SwiftEverywhere


## Overview

This demonstrates using Swift with a Raspberry Pi

## Raspberry Pi

Pi Model: Raspberry Pi 4 Model B Rev 1.4
Memory: 256GB mini-SD card. I originally used an 8GB card but it as not enough for installing Swift.
OS: Raspberry Pi OS (64-bit), from [Raspberry Pi Imager](https://www.raspberrypi.com/software)

When you reach the option to set "customizations":

## Run on Pi

* Download Visual Studio Code
* Install the Microsoft Remote - SSH to run on Pi from Mac

nohup swift run > output.log 2>&1 &

##  Create a systemd Service File

sudo vi /etc/systemd/system/swift_everywhere.service

```
[Unit]
Description=Swift Everywhere Service
After=network.target

[Service]
ExecStart=/usr/bin/bash run.sh
WorkingDirectory=/home/bill/SwiftEverywhere
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
