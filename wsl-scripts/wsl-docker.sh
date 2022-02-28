#!/bin/bash

# Install useful packages
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add docker package repository key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Get package repository updates
sudo apt-get update

## TODO These packages MUST be marked as hold to prevent updates without previous testing
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose

## Configure WSL to launch dockerd on startup
sudo systemctl enable docker.service
sudo systemctl enable containerd.service