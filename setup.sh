#!/bin/bash

# Install server deps
sudo apt -q -y install nginx certbot
sudo add-apt-repository ppa:certbot/certbot
sudo apt install python-certbot-nginx

# Create & configure pelias user
sudo useradd --create-home -p $( echo pelias | openssl passwd -1 -stdin ) -u 1100 pelias
sudo usermod -aG docker pelias
sudo usermod -aG sudo pelias

sudo su - pelias

# Checkout geocoder source
git clone https://github.com/NYCPlanning/labs-geosearch-docker.git geosearch
cd geosearch
mkdir -p /data/elasticsearch

# Set up custom nginx config
sudo cp nginx.conf /etc/nginx/conf.d/geosearch.planninglabs.nyc.conf
sudo systemctl restart nginx

# Set up and run geocoder
./pelia compose pull

./pelias normalize nycpad 19a #figure out a way to programatically determine correct PAD version? update R script so that it is REQUIRED to be supplied, no default?

./pelias compose up elasticsearch

./pelias elastic create

./pelias compose up api placeholder libpostal

./pelias import nycpad
