# Migrating from Geosearch v1 to v2
This document outlines why we are introducing "v2" of the Geosearch API and how to migrate client application to use it, including details on breaking changes.

> This document assumes you are somewhat familiar with the underlying open source software that powers Geosearch. If you aren't please read through `README.md` and then come back.

## The "why?"
1. As of December 2022, the "v1" version of the API relied on end-of-life versions of several underlying languages and open source tools.
2. The work required to update those dependencies necessitated a switch to using Pelias' official [csv-importer](https://github.com/pelias/csv-importer) for importing our custom normalized PAD data into the Pelias ElasticSearch database.
3. When using that importer, arbitrary data that we attach to each record, such as BBL and BIN, are automatically nested with each feature's `properties` object in an object called `addendum`. Because this data is kept in a different property in "v1", this means we had to introduce minor breaking changes to the responses returned by the Geosearch API.

## Breaking changes
1. The paths to the endpoints for the API are the same aside from having to switch `/v1` to `/v2`. For instance `https://geosearch.planninglabs.nyc/v1/autocomplete?text=120%20broadway` becomes `https://geosearch.planninglabs.nyc/v2/autocomplete?text=120%20broadway`.
2. The "custom" data we add to each record are now found under `addendum` in each geojson feature's `properties` object under new keys. Here are examples of are examples of the old and new response objects for reference. For instance, to get at the bbl for a particular feature, you would access `feature.properties.addendum.pad.bbl` instead of `feature.properties.pad_bbl`. You will also notice that some extraneous properties such as `pad_orig_stname` have been removed for brevity. If you are a user of Geosearch and have any questions regarding this migration, please reach out to OpenSource_DL@planning.nyc.gov.

#### Old
```
{
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          -74.01054,
          40.708225
        ]
      },
      "properties": {
        "id": "3945",
        "gid": "nycpad:address:3945",
        "layer": "address",
        "source": "nycpad",
        "source_id": "3945",
        "name": "120 BROADWAY",
        "housenumber": "120",
        "street": "BROADWAY",
        "postalcode": "10271",
        "accuracy": "point",
        "country": "United States",
        "country_gid": "whosonfirst:country:85633793",
        "country_a": "USA",
        "region": "New York State",
        "region_gid": "whosonfirst:region:0",
        "region_a": "NY",
        "county": "New York County",
        "county_gid": "whosonfirst:county:061",
        "locality": "New York",
        "locality_gid": "whosonfirst:locality:0",
        "locality_a": "NYC",
        "borough": "Manhattan",
        "borough_gid": "whosonfirst:borough:1",
        "label": "120 BROADWAY, Manhattan, New York, NY, USA",
        "pad_low": "104",
        "pad_high": "124",
        "pad_bin": "1001026",
        "pad_bbl": "1000477501",
        "pad_geomtype": "bin",
        "pad_orig_stname": "BROADWAY"
      }
    }
```

#### New
```
{
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          -74.01052,
          40.70822
        ]
      },
      "properties": {
        "id": "3892",
        "gid": "nycpad:venue:3892",
        "layer": "venue",
        "source": "nycpad",
        "source_id": "3892",
        "country_code": "US",
        "name": "120 BROADWAY",
        "housenumber": "120",
        "street": "BROADWAY",
        "postalcode": "10271",
        "accuracy": "point",
        "country": "United States",
        "country_gid": "whosonfirst:country:85633793",
        "country_a": "USA",
        "region": "New York",
        "region_gid": "whosonfirst:region:85688543",
        "region_a": "NY",
        "county": "New York County",
        "county_gid": "whosonfirst:county:102081863",
        "locality": "New York",
        "locality_gid": "whosonfirst:locality:85977539",
        "locality_a": "NYC",
        "borough": "Manhattan",
        "borough_gid": "whosonfirst:borough:421205771",
        "neighbourhood": "Financial District",
        "neighbourhood_gid": "whosonfirst:neighbourhood:85865711",
        "label": "120 BROADWAY, New York, NY, USA",
        "addendum": {
          "pad": {
            "bbl": "1000477501",
            "bin": "1001026"
          }
        }
      }
    },
```