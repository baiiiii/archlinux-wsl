#!/bin/bash

# Cancel the systemd-firstboot.service at first run which hangs forever, preventing any other systemd services to start.
systemctl cancel $(systemctl list-jobs | grep systemd-firstboot.service | awk '{print $1}')
