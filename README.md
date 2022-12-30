Docker Compose project for NYC Geosearch service, built on the open source [Pelias](https://github.com/pelias/pelias) geocoder and [NYC's Property Address Directory (PAD)](https://www1.nyc.gov/site/planning/data-maps/open-data.page)

## Overview

- [About](#about)
- [Config-Driven](#config-driven)
- [Pelias CLI tool](pelias-cli-tool)
- [Running Geosearch Locally](#running-geosearch-locally)
- [Deployment](#redeploying-geosearch-for-quarterly-data-updates)
- [How exactly to deployments work?](#how-exactly-to-deployments-work)

## About

This repo serves as "home base" for the GeoSearch project, as the docker compose project orchestrates a functioning set up.  Other relevant code for our Pelias deployment:

- [geosearch-pad-normalize](https://github.com/NYCPlanning/labs-geosearch-pad-normalize) - an R script that ingests and transforms raw Property Address Database (PAD) data, most significantly interpolating valid address ranges. This repo ouputs a csv that conforms to the data schema required by Pelias' official [CSV Importer](https://github.com/pelias/csv-importer). Note that this repo used to output data meant to be ingested by the now deprecated [PAD Importer](https://github.com/NYCPlanning/labs-geosearch-pad-importer) project.
- [geosearch-docs](https://github.com/NYCPlanning/labs-geosearch-docs) - an interactive documentation site for the Geosearch API

Docker Compose allows us to quickly spin up the pelias services we need, and run scripts manually in the containers.  It also makes use of volumes and internal hostnames so the various services can communicate with each other. The contents of `docker-compose.yml` are based on code from the [pelias/docker](https://github.com/pelias/docker) project.

> There is one service in `docker-compose.yml` that did not come from the `pelias/docker` project and that is the one called `nginx`. We added a simple [nginx](https://nginx.org/en/) server here that uses the contents of `nginx.conf` to serve as a reverse proxy server to direct traffic to either the Geosearch docs [website](https://github.com/NYCPlanning/labs-geosearch-docs) or forward it to the Pelias API itself.

For more information on Pelias services, including many which we are not using here at City Planning, check out the `pelias/docker` project, or their [documentation](https://github.com/pelias/documentation)

## Config-Driven

Much of this environment is config-driven, and the two files you should pay attention to are:

- [docker-compose.yml](https://github.com/NYCPlanning/labs-geosearch-dockerfiles/blob/master/pelias.json) - configurations for each of the named services, including images to use, environment variable definitions, and volume mounts.
- [pelias.json](https://github.com/NYCPlanning/labs-geosearch-docker/blob/master/pelias.json) - a shared config file used by all of the pelias services

## Pelias CLI tool

All steps needed to get an instance of Geosearch up and running are encapsulated within commands that can be run via the `pelias` CLI tool included in this repo. This CLI tool is comprised of the file `pelias` at the root of this repo, as well as the files found in `/lib` and `/cmd`. All of these files were taken directly from [this Pelias repo](https://github.com/pelias/docker) outlining how to run Pelias via docker and docker-compose. **Note that these files are up to date with that Pelias repo as of December 2022, but changes to that repo will not be automatically reflected in this repo.**. If you would like to set up the CLI locally, see the docs in the /pelias/docker repo.

> If you are having trouble setting up the CLI, or would just prefer not to add a record to your `$PATH`, you should be able to call the file at `./pelias` directly. To do this when running the commands in the "Running Geosearch Locally" section below, just replace `pelias` with `./pelias` in the commands. For instance `pelias compose pull` becomes `./pelias compose pull`

## Running Geosearch Locally

You can run Geosearch locally using the included `pelias` CLI and docker-compose.yml file. The following instructions assume that you have set up the Pelias CLI locally and have docker and docker-compose installed on your machine.

Run these commands from the root directory of this repo:

First, create the requisite folder for the docker volumes. Note that the `./data` folder and its contents will be gitignored
```
mkdir -p data/elasticsearch data/csv data/whosonfirst
```

Create a `.env` file and set the `DATA_DIR` environment variables for Pelias
```
echo "DATA_DIR=$(pwd)/data" > .env
```

Pull images
```
pelias compose pull
```

Start the ElasticSearch service
```
pelias elastic start
```

Wait for it to come up. **This may take longer than the timeout period built into the pelias CLI. If you get a message saying elasticsearch did not come up, try running this command a few times to see if you get the "Elasticsearch up!" message eventually**
```
pelias elastic wait
```

Create the index in EL
```
pelias elastic create
```

Download the required Who's On First dataset
```
pelias download wof
```

Download the normalized PAD CSV
```
pelias download csv
```

Import the normalized PAD data into the elasticsearch datastore. This will likely take a while.
```
pelias import csv
```

Bring up the rest of the necessary docker services, including the Pelias API and nginx server
```
pelias compose up
```

To confirm that everything is up and running, you can try to hit the API. For instance, a `GET` call to `http://localhost/v2/autocomplete?text=120%20broadway` should return results for 120 Broadway.

## Redeploying Geosearch for Quarterly Data Updates

> The following section is only relevant to members of DCP's Open Source Engineering team responsible for maintaining Geosearch

When a new quarterly update of PAD becomes available on Bytes of the Big Apples:

1. Head to [geosearch-pad-normalize](https://github.com/NYCPlanning/labs-geosearch-pad-normalize) and perform the process outlined there for building a new version of the normalized PAD data. Once you have merged a pull request in the `main` branch of that repo, you can monitor the progress of building and uploading the new data in the [actions for that repo](https://github.com/NYCPlanning/labs-geosearch-pad-normalize/actions). This will produce the latest version of normalized pad and upload the new CSV file to the correct DigitalOcean Space.

2. Confirm that the csv outputed by geosearch-pad-normalize has been uploaded to the "latest" folder in Digital Ocean. You can see the exact URL that this repo will attempt to download the data from by looking at the value in `imports.csv.download` in `pelias.json`. **Note that you should not have to make changes to `pelias.json` in order to do data updates.**

3. Run the "Build and Deploy" GH Action workflow. This workflow will run automatically on pushes to `main`. However, if you are only trying to deploy a new instance of Geosearch with a new version of PAD, you should not need to make any code changes to this repo. Because of that, the workflow can also be run manually. To do that, go to the "Actions" tab in the repo and select the "Build and Deploy" worklow from the list on the left-hand side. Then select "Run workflow" with the `main` branch selected. 

4. The workflow will create the new Droplet in Digital Ocean and run the commands in `cloud-config.yml`. This will initialize all of the containers in `docker-compose.yml`, download the PAD data, and import it into Pelias' ElasticSearch database. Finally, the workflow will run `wait_for_200.sh` every 30 seconds for up to 1 hour so that the workflow will end with a successful status if and when your new Geosearch instance is up and ready to start receiving traffic.

> As of December 2022, it typically takes about 30-45 minutes for the the droplet to be created and for the services to fully reach a "healthy" status with all of the data loaded in. In some cases, it is possible that the GH Action job that runs `wait_for_200.sh` will finish "successfully" even though there was a failure. If that job finishes successfully much more quickly than we would expect, manually test the `/v2/autocomplete` endpoint to make sure the normalized PAD data was properly loaded before going to production.

5. Once the workflow finishes successfully, you should see a new geosearch droplet in Digital Ocean. You can verify that it is working properly by sending requests at it's public IPv4 address. Traffic to the production geosearch URL (https://geosearch.planninglabs.nyc/) is sent to the IP associated with the "geosearch" load balancer. To put your new droplet in production, simply add it to the new load balancer, remove the old droplet from the load balancer, and then delete the old droplet.

## How exactly to deployments work?

> The following explains what happens when we deploy a new Droplet running the code in this repo to Digital Ocean. If you are only trying to deploy a new instance of Geosearch with a new version of PAD data, everything you need should be covered in the "Deployment" section above.

Deployments are primarily handled by two files: `/.github/workflows/build.yml' and 'cloud-config.yml`. The "Build and Deploy" workflow in `build.yml` is run manually or triggered by pushes to the `main` branch (note that merging PRs into main constitutes a push). This workflow is responsible for a few things:
1. It uses `doctl` to create a new droplet. It will add an SSH public key saved in DO to that Droplet and tag it with `labs`. It will also point DO to the `cloud-config.yml` file for cloud-init to use for provisioning the droplet
2. Once the droplet is up, it will use the script in `wait_for_200.sh` to wait for the droplet to be healthy. In this scenario, healthy is defined as having all Geosearch services up and ready to accept traffic. This can take a while, primarily due to the time it takes to download the normalized PAD CSV and import it into the ElasticSearch datastore.

Spinning up the services defined in `docker-compose.yml` and downloading and importing data is done via the tool [cloud-init](https://cloudinit.readthedocs.io/en/latest/). cloud-init uses the contents of `cloud-config.yml` to do the following:
1. Create a new sudo user called `pelias` on the new droplet. This is necessary because, following best practice, the Pelias CLI tool cannot not be run as the `root` system user. It will assign this user to the correct groups and add the included public SSH key to it.
2. Disable root access. As a security measure, logging into the droplet as `root` will be disabled once it is initialized.
3. Install the `docker` and `docker-compose` packages.
4. Bring up Geosearch by running the commands under `runcmd`. Note that even though `cloud-config.yml` creates the pelias user, the commands in `runcmd` are executed **as root**. Most of these commands use `runuser` to execute commands as the pelias user.

> If you find yourself needing to ssh into a deployed Geosearch droplet, please see your team lead for additional instructions.
