# SwiftEverywhere

## Raspberry Pi

For this experiment, a Raspberry Pi 4 Model B Rev 1.4

I used a 258GB mini-SD card. Origianlly I used an 8GB card but it as not enough for installing Swift.

I installed Raspberry Pi OS (64-bit), using the [Raspberry Pi Imager](https://www.raspberrypi.com/software)

When you reach the option to set "customizations":


## Local Development

* Download Visual Studio Code
* Install the Microsoft Remote - SSH to run on Pi from Mac

## Run

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

sudo systemctl enable my_service.service

### Get Status

sudo systemctl status swift_everywhere.service

### Stop and Restart the Service

sudo systemctl stop my_service.service
sudo systemctl restart my_service.service

### Log Output

sudo journalctl -u my_service.service