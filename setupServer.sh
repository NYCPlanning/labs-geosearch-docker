#!/bin/bash

# Install server deps
sudo apt -q -y install nginx certbot
sudo add-apt-repository ppa:certbot/certbot
sudo apt -q -y install python-certbot-nginx

# Create & configure pelias user
sudo useradd --create-home -p $( echo pelias | openssl passwd -1 -stdin ) -u 1100 pelias
sudo usermod -aG docker pelias
sudo usermod -aG sudo pelias
sudo usermod --shell /bin/bash pelias

sudo su - pelias

# Checkout geocoder source
git clone https://github.com/SPTKL/labs-geosearch-docker.git geosearch

# Set up custom nginx config
sudo cp geosearch/nginx.conf /etc/nginx/conf.d/geosearch.planninglabs.nyc.conf
sudo systemctl restart nginx
