locals {
  droplet_name = "geosearch-${var.pad_version}-${formatdate("YYYY-MM-DD-hh'h'mm", timestamp())}"
  normalized_pad_url = "https://planninglabs.nyc3.digitaloceanspaces.com/geosearch-data/${var.pad_version}/labs-geosearch-pad-normalized.zip"
}

resource "digitalocean_droplet" "server" {
  image  = "docker-20-04"
  name   = local.droplet_name
  region = "nyc3"
  size   = "s-4vcpu-8gb"
  tags = [
    data.digitalocean_tag.green.name,
    data.digitalocean_tag.labs.name,
  ]
  private_networking = true
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
    # data.digitalocean_ssh_key.geosearch.id
  ]
  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.pvt_key)
    timeout     = "120m"
  }

  # set up server with sudo user pelias
  provisioner "remote-exec" {
    inline = [
      # Adding user pelias
      "useradd --create-home -u 1100 pelias",
      "echo '${var.password}' | passwd pelias --stdin",
      "usermod -aG docker pelias",
      "usermod -aG sudo pelias",
      "usermod --shell /bin/bash pelias",

      # Adding terraform ssh keys to authorized keys
      "mkdir -p /home/pelias/.ssh",
      "touch /home/pelias/.ssh/authorized_keys",
      "echo '${data.digitalocean_ssh_key.terraform.public_key}' > authorized_keys",
      # "echo '${data.digitalocean_ssh_key.geosearch.public_key}' > authorized_keys",
      "mv authorized_keys /home/pelias/.ssh",
      "chown -R pelias:pelias /home/pelias/.ssh",
      "chmod 700 /home/pelias/.ssh",
      "chmod 600 /home/pelias/.ssh/authorized_keys",

      # Install unzip and create data folders for nycpad, whosonfirst, and elasticsearch
      # "apt install -y unzip",
      # "runuser -l pelias -c 'mkdir -p /home/pelias/geosearch/data'",
      # "runuser -l pelias -c 'mkdir -p /home/pelias/geosearch/data/elasticsearch'",
      # "runuser -l pelias -c 'mkdir -p /home/pelias/geosearch/data/csv'",
      # "runuser -l pelias -c 'mkdir -p /home/pelias/geosearch/data/whosonfirst'"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.pvt_key)
      timeout     = "120m"
    }
  }

  # Copy current repo directory to server /home/pelias/geosearch
  provisioner "file" {
    source      = "${abspath(path.root)}/"
    destination = "/home/pelias/geosearch"

    connection {
      type        = "ssh"
      user        = "pelias"
      private_key = file(var.pvt_key)
      timeout     = "120m"
    }
  }

  # Set up geosearch
  provisioner "remote-exec" {
    inline = [
      # create elasticsearch data mount dir with correct permissions
      "cd /home/pelias/geosearch",
      "mkdir data",
      "cd data",
      "mkdir elasticsearch",
      "mkdir csv",
      "mkdir whosonfirst",
      "export DATA_DIR=$(pwd)/data",
      "export DOCKER_USER=1100",

      # Allow execution for the pelias cli
      "chmod +x ./pelias",

      # Pulling normalized pad from digitalocean spaces
      # "echo 'Downloading file at ${local.normalized_pad_url}...'",
      # "curl -o data/nycpad/labs-geosearch-pad-normalized.zip ${local.normalized_pad_url}",
      # "echo 'Unzipping file...'",
      # "(cd data/nycpad; unzip labs-geosearch-pad-normalized.zip)",
      # "echo 'Finished unzipping'",

      # Set up the correct permission for elasticsearch
      # "echo '${var.password}' | sudo -S -n chown 1100 -R data",
      # "echo '${var.password}' | sudo -S -n chown 1100 -R data/elasticsearch",
      # "echo '${var.password}' | sudo -S -n chown 1100 -R data/csv",
      # "echo '${var.password}' | sudo -S -n chown 1100 -R data/whosonfirst",

      # Pull images
      "./pelias compose pull",

      # Download WoF and CSV data
      "./pelias download wof",
      "./pelias download csv",

      # Bring up elasticsearch ...
      "./pelias compose up elasticsearch",
      "./pelias elastic wait",
      "./pelias elastic create",

      # Import csv
      "./pelias import csv",

      # Bringing up libpostal and api
      "./pelias compose up api libpostal nginx"
    ]

    connection {
      type        = "ssh"
      user        = "pelias"
      private_key = file(var.pvt_key)
      timeout     = "120m"
    }
  }

  # Authenticate and login
  provisioner "local-exec" {
    command = "doctl auth init -t ${var.do_token}"
  }

}

output "ipv4_address" {
  value     = digitalocean_droplet.server.ipv4_address
  sensitive = true
}
