#!/bin/bash
PAD_VERSION=$1
if [ -z "$PAD_VERSION" ]; then
    echo "pad version must be supplied to setup geosearch with this script"
    echo "Usage: ./setupGeosearch.sh PAD_VERSION"
    exit 1
fi

echo "creating ES index..."
./pelias elastic create

echo "normalizing NYC PAD..."
./pelias normalize nycpad $PAD_VERSION

echo "importing NYC PAD..."
./pelias import nycpad

echo "pointing ES alias at newly populated index..."
./pelias elastic alias

echo "all done!"
