#!/bin/bash

# Switch to pelias user
sudo su - pelias

# create elasticsearch data mount dir with correct permissions
cd geosearch
mkdir -p data/elasticsearch
mkdir -p data/nycpad && (
  cd data/nycpad
  curl -O https://planninglabs.nyc3.digitaloceanspaces.com/geosearch-data/labs-geosearch-pad-normalized-sample-md.zip
  unzip labs-geosearch-pad-normalized-sample-md.zip
  mv labs-geosearch-pad-normalized-sample-md.csv labs-geosearch-pad-normalized.csv
  rm *.zip
  ls
)
sudo chown 1000:1000 -R data
sudo chown 1000:1000 -R data/elasticsearch
sudo chown 1000:1000 -R data/nycpad
ls -n data

export DATA_DIR=$(pwd)/data
export DOCKER_USER="1000:1000"

echo "Bringing up elasticsearch..."
./pelias compose up elasticsearch
./pelias elastic wait
./pelias elastic create
./pelias elastic indices
./pelias import nycpad

echo "Bringing up libpostal, and api..."
./pelias compose up api libpostal

echo "All done!"
