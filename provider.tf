terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.4.0"
    }
  }
}

variable "do_token" {}
variable "pvt_key" {}
variable "password" {}
variable "pad_version" {}
variable "loadbalancer" {}

provider "digitalocean" {
  token = var.do_token
}

# data "digitalocean_ssh_key" "terraform" {
#   name = "terraform"
# }

data "digitalocean_ssh_key" "geosearch" {
  name = "geosearch"
}

data "digitalocean_tag" "green" {
  name = "green"
}

data "digitalocean_tag" "labs" {
  name = "labs"
}