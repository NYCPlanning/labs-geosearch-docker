Docker Compose project for NYC Geosearch service, built on the open source [Pelias](https://github.com/pelias/pelias) geocoder and [NYC's Property Address Directory (PAD)](https://www1.nyc.gov/site/planning/data-maps/open-data.page)

## Overview

- [About](#about)
- [Config-Driven](#config-driven)
- [Pelias CLI tool](pelias-cli-tool)
- [Running Pelias Services](#running-pelias-services)
- [Schema Customization through Mounting](#schema-customization-through-mounting)
- [Production Domain](#production-domain)
- [Deployment 🚀](#deployment-)

## About

These dockerfiles allow for quickly standing up all of the services that work together to run the pelias geocoder, and is used in both production and development. These include:

- Modified Pelias API - node.js HTTP API that parses search strings and returns results from ES backend, using our custom Document schema
- [Libpostal service](https://github.com/pelias/libpostal-service) - a supporting service for Pelias API that parses addresses with ML-trained models
- Elasticsearch - the backend for the geocoder, where all address data is stored

This repo serves as "home base" for the GeoSearch project, as the docker compose project orchestrates a functioning set up.  Other relevant code for our Pelias deployment:

- [geosearch-pad-normalize](https://github.com/NYCPlanning/labs-geosearch-pad-normalize) - an R script that ingests and transforms raw Property Address Database (PAD) data, most significantly interpolating valid address ranges.
- [geosearch-pad-importer](https://github.com/NYCPlanning/labs-geosearch-pad-importer) - a Pelias importer for normalized NYC PAD data.
- [geosearch-docs](https://github.com/NYCPlanning/labs-geosearch-docs) - an interactive documentation site for the Geosearch API
- [geosearch-acceptance-tests](https://github.com/NYCPlanning/labs-geosearch-acceptance-tests) - nyc-specific test suite for geosearch

Docker Compose allows us to quickly spin up the pelias services we need, and run scripts manually in the containers.  It also makes use of volumes and internal hostnames so the various services can communicate with each other.
We are leveraging a CLI tool `pelias` introduced in the recent [pelias/docker](https://github.com/pelias/docker) project. Here it had been trimmed down and modified to address the specific use-cases of our project
For more information on Pelias services, including many which we are not using here at City Planning, check out the `pelias/docker` project, or their [documentation](https://github.com/pelias/documentation)

## Config-Driven

Much of this environment is config-driven, and the two files you should pay attention to are:

- [docker-compose.yml](https://github.com/NYCPlanning/labs-geosearch-dockerfiles/blob/master/pelias.json) - configurations for each of the named services, including images to use, environment variable definitions, and volume mounts.
- [pelias.json](https://github.com/NYCPlanning/labs-geosearch-docker/blob/master/pelias.json) - a shared config file used by all of the pelias services

## Pelias CLI tool

All steps needed to get an instance of Geosearch up and running are encapsulated within commands that can be run via the `pelias` CLI tool included in this repo. This CLI tool is comprised of the file `pelias` at the root of this repo, as well as the files found in `/lib` and `/cmd`. All of these files were taken directly from [Pelias' official repo](https://github.com/pelias/docker) outlining how to run Pelias via docker and docker-compose. **Note that these files are up to date with that Pelias repo as of December 2022, but changes to that repo will not be automatically reflected in this repo.**. If you would like to set up the CLI locally, see the docs in the /pelias/docker repo. 
## Running Pelias Services

1. __Install CLI tool__

    See above


3. __Bring up Elasticsearch and Create Index__

    Index name can be specified in pelias.json, as `schema.indexName`

    ```sh
    $ pelias compose up elasticsearch

    Creating pelias_elasticsearch ... done

    $ pelias elastic create
    --------------
    create index
    --------------

    [put mapping]    pelias { acknowledged: true,
      shards_acknowledged: true,
      index: 'pelias' }

    $ pelias elastic indices # to confirm index was correctly created, get all indices
    health status index  uuid                   pri rep docs.count docs.deleted store.size pri.store.size
    green  open   pelias aTRPQXrZQMm4Dboo3AI8gg   5   0          0            0       810b           810b
    ```

    Note: As with the download step, if elasticsearch and schema images have not yet been pulled, they will be pulled and built as part of these steps

4. __Import PAD Data__

    This step runs the PAD importer to load downloaded PAD data into the running ES database. For more information, see the [Pad Importer](https://github.com/NYCPlanning/labs-geosearch-pad-importer)

    ```sh
    $ pelias import nycpad
    2019-02-14T16:45:27.109Z - info: [nycpad] Creating read stream for: /data/nycpad/labs-geosearch-pad-normalized.csv
    2019-02-14T16:45:27.939Z - info: [dbclient]  paused=true, transient=10, current_length=0
    2019-02-14T16:45:27.940Z - info: [dbclient]  paused=true, transient=10, current_length=0
    2019-02-14T16:45:37.908Z - info: [dbclient]  paused=true, transient=8, current_length=0, indexed=2314, batch_ok=2314, batch_retries=0,
    failed_records=0, address=2314, persec=231.4
    2019-02-14T16:45:47.909Z - info: [dbclient]  paused=true, transient=7, current_length=0, indexed=5779, batch_ok=5779, batch_retries=0,
    failed_records=0, address=5779, persec=346.5
    2019-02-14T16:45:57.909Z - info: [dbclient]  paused=true, transient=10, current_length=0, indexed=8344, batch_ok=8344, batch_retries=0,
     failed_records=0, address=8344, persec=256.5
    2019-02-14T16:46:07.875Z - info: [dbclient]  paused=true, transient=5, current_length=0, indexed=11901, batch_ok=11901, batch_retries=0
    , failed_records=0, address=11901, persec=355.7
    ...
    ```

    Note: Importing the entire PAD dataset will take a fair amount of time and space. If you are bootstrapping/developing, it is recommended to download and import a smaller sample of the dataset #TODO ADD LINK TO importer repo

5. __Bring UP API and Supporting Services__

    The importer and schema containers are ephemeral, meaning that they will exit(0) immediately upon being run. This means you're free to bring up the whole docker compose project, and only the containers that should persist (pelias API, and placeholder and libpostal services) will persist. Alternatively you can specify which containers you'd like to bring up

    ```sh
    $ pelias compose up api libpostal

    OR

    $ pelias compose up
    ```

    Note: The libpostal service requires significant memory to function, around 2G for just this one service. Be sure to bump up your docker memory allocation before trying to run all the services at once.

6. __Confirm everything is working!__

    ```sh
    $ docker-compose ps
            Name                      Command               State                       Ports
    --------------------------------------------------------------------------------------------------------------
    pelias_api             ./bin/start                      Up      0.0.0.0:4000->4000/tcp
    pelias_elasticsearch   /bin/bash bin/es-docker          Up      0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp
    pelias_libpostal       ./bin/wof-libpostal-server ...   Up      0.0.0.0:4400->4400/tcp

    # confirm libpostal is running & working
    $ curl -s localhost:4400/expand?address=120%20Broadway%20NY%20NY | jq
    [
      "120 broadway ny ny",
      "120 broadway ny new york",
      "120 broadway new york ny",
      "120 broadway new york new york"
    ]

    # confirm pelias API is running & working
    $ curl -s localhost:4000/status
    status: ok

    $ curl -s localhost:4000/v1/autocomplete?text=1415%20ave%20w | jq 'keys' # only showing top level keys here for brevity
    [
      "bbox",
      "features",
      "geocoding",
      "type"
    ]
    ```


## Production Domain

In production, we added a custom nginx configuration to handle SSL, and route traffic to the pelias api running internally on port 4000.  The nginx config [Jinja2](http://jinja.pocoo.org/) template is saved in this repo as [`nginx.conf`](nginx.conf).

This nginx config also proxies all requests that aren't API calls to the geosearch docs site, so that both the API and the docs can share the same production domain.

## Deployment 🚀

> The following section is only relevant to members of DCP's Open Source Engineering team responsible for maintaining Geosearch

When a new quarterly update of PAD available on Bytes of the Big Apples:

1. Head to [geosearch-pad-normalize](https://github.com/NYCPlanning/labs-geosearch-pad-normalize) to trigger a PAD Normalization process. Which will produce the latest version of normalized pad and deploy to DigitalOcean Spaces.

2. Confirm that the csv outputed by geosearch-pad-normalize has been uploaded to the "latest" folder in Digital Ocean. You can see the exact URL that this repo will attempt to download the data from by looking at the value in `imports.csv.download` in `pelias.json`. **Note that you should not have to make changes to `pelias.json` in order to do data updates.**

> Based on the pull request, terraform will generate an execution plan and post the plan in the pull request comment section.

3. Run the "Build and Deploy" GH Action workflow. This workflow will run automatically on pushes to `main`. However, if you are only trying to deploy a new instance of Geosearch with a new version of PAD, you should not need to make any code changes to this repo. Because of that, the workflow can also be run manually. To do that, go to the "Actions" tab in the repo and select the "Build and Deploy" worklow from the list on the left-hand side. Then select "Run workflow" with the `main` branch selected. 

4. The workflow will create the new Droplet in Digital Ocean and run the commands in `cloud-config.yml`. This will initialize all of the containers in `docker-compose.yml`, download the PAD data, and import it into Pelias' ElasticSearch database. Finally, the workflow will run `wait_for_200.sh` every 30 seconds for up to 1 hour so that the workflow will end with a successful status if and when your new Geosearch instance is up and ready to start receiving traffic.

5. Once the workflow finishes successfully, you should see a new geosearch droplet in Digital Ocean. You can verify that it is working properly by sending requests at it's public IPv4 address. Traffic to the production geosearch URL (https://geosearch.planninglabs.nyc/) is sent to the IP associated with the "geosearch" load balancer. To put your new droplet in production, simply add it to the new load balancer, remove the old droplet from the load balancer, and then delete the old droplet.
