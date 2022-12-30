#/bin/bash

set -e;

function health_status(){
  curl \
    --output /dev/null \
    --silent \
    --write-out "%{http_code}" \
    "http://$1/v2/autocomplete?text=120%20broadway" \
      || true;
}

function health_wait(){
  echo 'waiting for healthcheck to $1 to return 200';
  retry_count=120

  i=1
  while [[ "$i" -le "$retry_count" ]]; do
    if [[ $(health_status $1) -eq 200 ]]; then
      echo "Geosearch is up!"
      exit 0
    else
      echo "Healthcheck did not return 200 status code. Trying again in 30 seconds..."
    fi
    sleep 30
    i=$(($i + 1))
  done

  echo -e "\n"
  echo "Geosearch did not come up. Check cloudinit logs for details."
  exit 1
}

for var in "$@"; do
    health_wait "$var"
done