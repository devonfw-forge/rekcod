#!/bin/bash

echo '[Unit]
Description=Expose docker daemon to Windows
After=docker.service
BindsTo=docker.service
ReloadPropagatedFrom=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/expose-docker.sh
ExecReload=/usr/bin/expose-docker.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/rekcod.service

sudo systemctl daemon-reload
sudo systemctl enable rekcod.service
