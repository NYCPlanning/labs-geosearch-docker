resource "digitalocean_droplet" "EDM" {
    image = "docker-20-04"
    name = "geosearch-stg"
    region = "nyc3"
    size = "s-4vcpu-8gb"
    private_networking = true
    ssh_keys = [
      data.digitalocean_ssh_key.terraform.id
    ]
    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        private_key = file(var.pvt_key)
        timeout = "1m"
    }

    provisioner "remote-exec" {
        inline = [
            "useradd --create-home -p $( echo pelias | openssl passwd -1 -stdin ) -u 1100 pelias",
            "passwd -d pelias",
            "usermod -aG docker pelias",
            "usermod -aG sudo pelias",
            "usermod --shell /bin/bash pelias",
            "mkdir -p /home/pelias/.ssh",
            "touch /home/pelias/.ssh/authorized_keys",
            "echo '${file(var.pub_key)}' > authorized_keys",
            "mv authorized_keys /home/pelias/.ssh",
            "chown -R pelias:pelias /home/pelias/.ssh",
            "chmod 700 /home/pelias/.ssh",
            "chmod 600 /home/pelias/.ssh/authorized_keys",
            "apt -q -y install nginx certbot python3-certbot-nginx"
        ]

        connection {
            type = "ssh"
            user = "root"
            private_key = file(var.pvt_key)
        }
    }

    provisioner "file" {
        source      = var.pwd
        destination = "/home/pelias/geosearch"

        connection {
            type = "ssh"
            user = "pelias"
            private_key = file(var.pvt_key)
        }
    }
 
    provisioner "remote-exec" {
        inline = [
            "cp /home/pelias/geosearch/nginx.conf /etc/nginx/conf.d/geosearch.planninglabs.nyc.conf",
            "systemctl restart nginx"
        ]

        connection {
            type = "ssh"
            user = "root"
            private_key = file(var.pvt_key)
        }
    }

    provisioner "remote-exec" {
        inline = [
            # create elasticsearch data mount dir with correct permissions
            "cd /home/pelias/geosearch",
            "sudo mkdir -p data/elasticsearch",
            "export DATA_DIR=$(pwd)/data",
            "export DOCKER_USER=1100",

            # Set up and run geocoder
            # Bringing up elasticsearch...
            "chmod +x ./pelias",
            "./pelias normalize nycpad 20a",
            "sudo chown 1100 -R data",
            "sudo chown 1100 -R data/elasticsearch",
            "sudo chown 1100 -R data/nycpad",
            "./pelias compose up elasticsearch",
            "./pelias elastic wait",
            "./pelias elastic create",
            "./pelias elastic indices",

            # Bringing up libpostal, and api...
            "./pelias compose up api libpostal",
            "./pelias import nycpad",
        ]

        connection {
            type = "ssh"
            user = "pelias"
            private_key = file(var.pvt_key)
        }
    }
}