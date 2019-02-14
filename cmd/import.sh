#!/bin/bash
set -e;

function import_nycpad() { compose_run 'nycpad' './bin/start'; }
register 'import' 'nycpad' '(re)import NYC PAD data' import_nycpad
