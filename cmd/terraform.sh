#!/bin/bash
set -e;

function terraform_plan() { 
    terraform plan\
        -var "do_token=${DO_PAT}" \
        -var "pvt_key=${PVT_KEY}" \
        -var "pub_key=${PUB_KEY}" \
        -var "password=${PASSWORD}"\
        -lock=false\
        -auto-approve
}
register 'terraform' 'plan' 'this is a dry run without actually creating a server in digitalocean' terraform_plan

function terraform_apply() { 
    terraform apply\
        -var "do_token=${DO_PAT}" \
        -var "pvt_key=${PVT_KEY}" \
        -var "pub_key=${PUB_KEY}" \
        -var "password=${PASSWORD}"\
        -lock=false\
        -auto-approve
}
register 'terraform' 'apply' 'actually applying terraform configurations' terraform_apply

function terraform_destroy() { 
    terraform destroy\
        -var "do_token=${DO_PAT}" \
        -var "pvt_key=${PVT_KEY}" \
        -var "pub_key=${PUB_KEY}" \
        -var "password=${PASSWORD}"\
        -lock=false\
        -auto-approve
}
register 'terraform' 'destroy' 'destroy the server/service that was just created as a clean up step' terraform_destroy