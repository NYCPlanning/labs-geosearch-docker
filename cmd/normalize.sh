#!/bin/bash
set -e;

function normalize_nycpad() { compose_run 'nycpad_normalizer' './bin/normalize' $@; }
register 'normalize' 'nycpad' '(re)download nycpad data, normalize, and save; version can optionally be specified' normalize_nycpad

