#!/bin/bash
set -e;

function download_placeholder() { compose_run 'placeholder' './bin/download'; }
register 'download' 'placeholder' '(re)download placeholder data' download_placeholder

