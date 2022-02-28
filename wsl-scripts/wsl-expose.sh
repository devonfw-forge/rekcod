#!/bin/bash

echo '#!/bin/bash

# Expose daemon to Windows
sudo cp /lib/systemd/system/docker.service /etc/systemd/system/
sudo sed -i '"'"'s/\ -H\ fd:\/\//\ -H\ fd:\/\/\ -H\ tcp:\/\/127.0.0.1:2375/g'"'"' /etc/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl restart docker.service ' > /usr/bin/expose-docker.sh

chmod +x /usr/bin/expose-docker.sh