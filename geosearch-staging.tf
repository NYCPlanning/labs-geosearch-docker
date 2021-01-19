resource "digitalocean_droplet" "geosearch_staging" {
    image = "docker-20-04"
    name = "geosearch-staging"
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
            "echo '${file(var.pub_key)}' > authorized_keys",
            "mv authorized_keys /home/pelias/.ssh",
            "chown -R pelias:pelias /home/pelias/.ssh",
            "chmod 700 /home/pelias/.ssh",
            "chmod 600 /home/pelias/.ssh/authorized_keys",

            # Install nginx and certbot (ignore nginx set up for now)
            # "apt -q -y install nginx certbot python3-certbot-nginx"
            "apt install -y unzip",
            "runuser -l pelias -c 'mkdir -p /home/pelias/geosearch/data/elasticsearch'",
            "runuser -l pelias -c 'mkdir -p /home/pelias/geosearch/data/nycpad'"
        ]

        connection {
            type = "ssh"
            user = "root"
            private_key = file(var.pvt_key)
        }
    }

    # Copy current repo directory to server /home/pelias/geosearch
    provisioner "file" {
        source      = "${abspath(path.root)}/"
        destination = "/home/pelias/geosearch"

        connection {
            type = "ssh"
            user = "pelias"
            private_key = file(var.pvt_key)
        }
    }
 
    # # Copy nginx config (ignore nginx set up for now)
    # provisioner "remote-exec" {
    #     inline = [
    #         "cp /home/pelias/geosearch/nginx.conf /etc/nginx/conf.d/geosearch.planninglabs.nyc.conf",
    #         "systemctl restart nginx"
    #     ]

    #     connection {
    #         type = "ssh"
    #         user = "root"
    #         private_key = file(var.pvt_key)
    #     }
    # }

    # Set up geosearch
    provisioner "remote-exec" {
        inline = [
            # create elasticsearch data mount dir with correct permissions
            "cd /home/pelias/geosearch",
            "export DATA_DIR=$(pwd)/data",
            "export DOCKER_USER=1100",

            # Allow execution for the pelias cli
            "chmod +x ./pelias",

            # Pulling normalized pad from digitalocean spaces
            # "./pelias normalize nycpad 20a",
            "curl -o data/nycpad/labs-geosearch-pad-normalized.zip https://planninglabs.nyc3.digitaloceanspaces.com/geosearch-data/labs-geosearch-pad-normalized.zip",
            "(cd data/nycpad; unzip labs-geosearch-pad-normalized.zip)",
            
            # Set up the correct permission for elasticsearch
            "echo '${var.password}' | sudo -S -n chown 1100 -R data",
            "echo '${var.password}' | sudo -S -n chown 1100 -R data/elasticsearch",
            "echo '${var.password}' | sudo -S -n chown 1100 -R data/nycpad",

            # Bring up elasticsearch ...
            "./pelias compose up elasticsearch",
            "./pelias elastic wait",
            "./pelias elastic create",
            "./pelias elastic indices",

            # Bringing up libpostal, and api...
            "./pelias compose up api libpostal",

            # Import pad, this would take a while
            "./pelias import nycpad",
        ]

        connection {
            type = "ssh"
            user = "pelias"
            private_key = file(var.pvt_key)
        }
    }
}