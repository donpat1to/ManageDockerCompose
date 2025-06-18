#!/bin/bash

echo "Stopping all Docker Compose services..."
for dir in /srv/*; do
    [ -f "$dir/docker-compose.yaml" ] && docker compose -f "$dir/docker-compose.yaml" down
done

echo "Updating system packages..."
apt update && apt upgrade -y

echo "Rebooting system..."
reboot
