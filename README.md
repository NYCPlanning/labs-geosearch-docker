Docker Compose project for NYC Geosearch Services,built on the open source [Pelias](https://github.com/pelias/pelias) geocoder and [NYC's Property Address Directory (PAD)](https://www1.nyc.gov/site/planning/data-maps/open-data.page)


## Overview

<img width="751" alt="screen shot 2018-01-18 at 1 12 07 pm" src="https://user-images.githubusercontent.com/1833820/35113991-48b04abc-fc51-11e7-8a4f-7664ddba6492.png">


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
All of the necessary steps/functionality have been wrapped in this `pelias` CLI tool. To set up the tool, add [`pelias` file](https://github.com/NYCPlanning/labs-geosearch-docker/blob/master/pelias) in this repo to your path, or create a symlink to the executable in an existing path location:

To add the location of the pelias executable to your PATH, run this from the root dir of this repo:
```sh
$ echo export PATH=$PATH:`pwd`/pelias >> ~/.bash_profile
$ source ~/.bash_profile
```

To add a symlink to the pelias executable to an existing PATH location (maybe `/usr/loca/bin`, `/usr/bin`, etc...), run this from the root dir of this repo:
```sh
$ ln -s `pwd`/pelias /usr/local/bin # or wherever you'd like to install the executable in your PATH
```

Once you have set up pelias, you can see all possible commands by running `pelias`:
```sh
$ pelias

Usage: pelias [command] [action] [options]

  compose    pull                   update all docker images
  compose    logs                   display container logs
  compose    ps                     list containers
  compose    top                    display the running processes of a container
  compose    exec                   execute an arbitrary docker-compose command
  compose    run                    execute a docker-compose run command
  compose    up                     start one or more docker-compose service(s)
  compose    kill                   kill one or more docker-compose service(s)
  compose    down                   stop all docker-compose service(s)
  download   placeholder            (re)download placeholder data
  elastic    drop                   delete elasticsearch index & all data
  elastic    create                 create elasticsearch index with pelias mapping
  elastic    alias                  Create or update specified alias to point to index defined in pelias.json
  elastic    start                  start elasticsearch server
  elastic    stop                   stop elasticsearch server
  elastic    status                 HTTP status code of the elasticsearch service
  elastic    wait                   wait for elasticsearch to start up
  elastic    aliases                show all elasticsearch aliases
  elastic    indices                show all elasticsearch indices
  import     nycpad                 (re)import NYC PAD data
  normalize  nycpad                 (re)download nycpad data, normalize, and save; version can optionally be specified

```
This is essentially a subset of commands/actions provided by the original tool, with a few operations added to manage PAD data

## Running Pelias Services
1. __Run PAD Download and Normalization__

    You can specify a PAD version to download by passing it to the pelias CLI command
    ```sh
    $ pelias normalize nycpad [PAD_VERSION]
    ```

2. __Bring up Elasticsearch and Create Index__

    Index name can be specified in pelias.json, as `schema.indexName`
    ```sh
    $ pelias compose up elastic

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

3. __Import PAD Data__

    This step runs the PAD importer to load downloaded PAD data into the running ES database. For more information, see the [Pad Importer](https://github.com/NYCPlanning/labs-geosearch-pad-importer)
    ```sh
    $ pelias import pad
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

4. __Bring UP API and Supporting Services__

    The importer and schema containers are ephemeral, meaning that they will exit(0) immediately upon being run. This means you're free to bring up the whole docker compose project, and only the containers that should persist (pelias API, and placeholder and libpostal services) will persist. Alternatively you can specify which containers you'd like to bring up
    ```sh
    $ pelias compose up api placeholder libpostal

    OR

    $ pelias compose up
    ```
    Note: The libpostal service requires significant memory to function, around 2G for just this one service. Be sure to bump up your docker memory allocation before trying to run all the services at once.

5. __Confirm everything is working!__
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

## Schema Customization through Mounting

Our geocoder needs to store and return a few additional fields in addition to those specified by the native pelias schema. We are overriding pelias schema by mounting a few custom files into the pre-built pelias images.

Mounted files can be seen in the [`mounts` directory](https://github.com/NYCPlanning/labs-geosearch-docker/tree/master/mounts). Some of these mounts are more straightforward, while others are more brittle and will hopefully be refactored to more stable solutions soon.

- The `schema` directory contains [`document.js`](https://github.com/NYCPlanning/labs-geosearch-docker/blob/master/mounts/schema/document.js), which adds `pad_meta` fields to the document schema registered with ES. This file is mounted into the `pelias/schema` container. This allows for us to maintain the `dynamic: 'strict'` settings also upheld by pelias, while storing our custom fields in a sane, reasonable way.

- The `api` directory contains [`helper/geojsonify_place_details.js`](https://github.com/NYCPlanning/labs-geosearch-docker/blob/master/mounts/api/helper/geojsonify_place_details.js#L61-L65) and [`middleware/renamePlacenames.js`](https://github.com/NYCPlanning/labs-geosearch-docker/blob/master/mounts/api/middleware/renamePlacenames.js#L60-L65), which together ensure the `pad_meta` fields are flattened into the top-level JSON object ultimately returned by the API. These files are mounted into the `pelias/api` container. This modification is vulnerable; it will break with any reorganization or redesign of the API code. It should be revisited, but works for now.

- The `bin` directory contains [`bin/placeholder_download`](https://github.com/NYCPlanning/labs-geosearch-docker/blob/master/mounts/bin/placeholder_download) which enables simple downloading of placeholder data by the placeholder image through the custom pelias CLI. This file is mounted into the placeholder container. It does not replace/interact with any of the source placeholder code, and should be stable.

## Production Domain

In production, we added a custom nginx configuration to handle SSL, and route traffic to the pelias api running internally on port 4000.  The nginx config [Jinja2](http://jinja.pocoo.org/) template is saved in this repo as [`nginx.conf`](nginx.conf).

The nginx config should be stored in `/etc/nginx/conf.d/{productiondomain}.conf`

This nginx config also proxies all requests that aren't API calls to the geosearch docs site, so that both the API and the docs can share the same production domain.
