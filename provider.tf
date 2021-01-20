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
variable "pub_key" {}
variable "password" {}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
}