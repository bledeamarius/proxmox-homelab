#!/bin/bash
set -e

cloud-init status --wait

sudo apt update && sudo apt upgrade -y

# ✅ Disable systemd-resolved — conflicts with Pi-hole on port 53
sudo systemctl disable --now systemd-resolved || true
sudo rm -f /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf

sudo apt install -y qemu-guest-agent curl
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

# Instal Docker + Docker Compose
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker debian
sudo systemctl enable --now docker
sudo apt-get install -y docker-compose-plugin

sudo mkdir -p /opt/docker
sudo chown debian:debian /opt/docker

# sudo docker rm -f pihole 2>/dev/null || true

# sudo docker run -d \
#   --name pihole \
#   --restart unless-stopped \
#   --network host \
#   -e TZ=Europe/Bucharest \
#   -e FTLCONF_webserver_api_password='YourPassword123' \
#   -v /opt/pihole/etc:/etc/pihole \
#   -v /opt/pihole/dnsmasq.d:/etc/dnsmasq.d \
#   --cap-add NET_ADMIN \
#   pihole/pihole:latest

