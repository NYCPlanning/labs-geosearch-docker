#!/bin/bash

# Switch to pelias user
sudo su - pelias

# create elasticsearch data mount dir with correct permissions
cd geosearch
mkdir -p data/elasticsearch

# Set up and run geocoder
echo "Pulling docker resources..."
./pelias compose pull

echo "Bringing up elasticsearch..."
./pelias compose up elasticsearch

echo "Bringing up libpostal, and api..."
./pelias compose up api libpostal

echo "All done!"
