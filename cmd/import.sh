#!/bin/bash
set -e;

function import_nycpad() { compose_run 'nycpad' './bin/start'; }
register 'import' 'nycpad' '(re)import NYC PAD data' import_nycpad

function import_whosonfirst() { compose_run 'whosonfirst' 'npm run download -- --admin-only'; }
register 'import' 'whosonfirst' 'import whosonfirst admin data' import_whosonfirst