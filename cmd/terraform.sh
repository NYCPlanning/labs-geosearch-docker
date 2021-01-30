#!/bin/bash
set -e;
PASSWORD=${PASSWORD:-$( echo pelias | openssl passwd -1 -stdin )}
PVT_KEY=${PVT_KEY:-~/.ssh/terraform}

function terraform_plan() { 
    terraform plan\
        -var "do_token=${DO_PAT}" \
        -var "pvt_key=${PVT_KEY}" \
        -var "password=${PASSWORD}"\
        -lock=false
}
register 'terraform' 'plan' 'this is a dry run without actually creating a server in digitalocean' terraform_plan

function terraform_apply() { 
    terraform apply\
        -var "do_token=${DO_PAT}" \
        -var "pvt_key=${PVT_KEY}" \
        -var "password=${PASSWORD}"\
        -lock=false\
        -auto-approve
}
register 'terraform' 'apply' 'actually applying terraform configurations' terraform_apply

function terraform_destroy() { 
    terraform destroy\
        -var "do_token=${DO_PAT}" \
        -var "pvt_key=${PVT_KEY}" \
        -var "password=${PASSWORD}"\
        -lock=false\
        -auto-approve
}
register 'terraform' 'destroy' 'destroy the server/service that was just created as a clean up step' terraform_destroy

function terraform_ssh() {
    ipv4_address=$(cat terraform.tfstate | jq -r '.resources[] | select(.type | contains("digitalocean_droplet")) | .instances[0] | .attributes.ipv4_address')
    ssh pelias@$ipv4_address -i $PVT_KEY
}
register 'terraform' 'ssh' 'ssh into the newly created digitalocean droplet' terraform_ssh