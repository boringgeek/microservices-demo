provider "google" {
    project     = "${var.project_name}"
    region      = "${var.region}"
    credentials = "${file("${var.credentials_file_path}")}"
}

resource "google_compute_firewall" "default" {
    name    = "docker-swarm-firewall"
    network = "default"

    allow {
        protocol        = "tcp"
        ports           = ["80", "30000", "22", "2377", "7946", "4789"]
    }

    source_ranges   = ["0.0.0.0/0"]
    target_tags     = ["docker-swarm-nodes", "docker-swarm-master"]

}

resource "google_compute_instance" "docker-swarm-node" {
    depends_on      = [ "google_compute_instance.docker-swarm-master" ] 
    count           = "2"
    machine_type    = "${var.machine_type}"
    name            = "docker-swarm-node-${count.index}"
    zone            = "${var.region_zone}"
    tags            = [ "docker-swarm-nodes" ]


    disk {
        image = "docker-swarm"
    }

    network_interface {
        network = "default"
        access_config {
            # Ephemeral
        }
    }

    metadata {
        ssh-keys = "root:${file("${var.public_key_path}")}"
    }

    connection {
        user        = "root"
        private_key = "${file("${var.private_key_path}")}"
    }

    provisioner "file" {
        source = "join.sh",
        destination = "/tmp/join.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo service docker start",
            "chmod +x /tmp/join.sh",
            "/tmp/join.sh"
        ]
    }
}

resource "google_compute_instance" "docker-swarm-master" {
    name            = "docker-swarm-master"
    machine_type    = "${var.machine_type}"
    zone            = "${var.region_zone}"
    tags            = [ "docker-swarm-master" ]


    disk {
        image = "docker-swarm"
    }

    network_interface {
        network = "default"
        access_config {
            # Ephemeral
        }
    }

    metadata {
        ssh-keys = "root:${file("${var.public_key_path}")}"
    }

    connection {
        user        = "root"
        private_key = "${file("${var.private_key_path}")}"
    }

    provisioner "file" { 
        source      = "../../docker-compose.yml"
        destination = "/tmp/docker-compose.yml"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo service docker start",
            "docker swarm init",
        ]
    }

    provisioner "local-exec" {
        command = "TOKEN=$(ssh -i \"${var.private_key_path}\" -o \"StrictHostKeyChecking no\" -o \"UserKnownHostsFile /dev/null\" root@${self.network_interface.0.access_config.0.assigned_nat_ip} docker swarm join-token -q worker); echo \"#!/usr/bin/env bash\ndocker swarm join --token $TOKEN ${self.network_interface.0.access_config.0.assigned_nat_ip}:2377\" >| join.sh"
    }
}

resource "null_resource" "docker-swarm" {
  depends_on = [ "google_compute_instance.docker-swarm-node" ] 
  connection {
    user        = "root"
    private_key = "${file("${var.private_key_path}")}"
    host        = "${google_compute_instance.docker-swarm-master.network_interface.0.access_config.0.assigned_nat_ip}"
  }
  provisioner "remote-exec" {
    inline = [
        "docker-compose -f /tmp/docker-compose.yml pull",
        "docker-compose -f /tmp/docker-compose.yml bundle -o dockerswarm.dab",
        "docker deploy dockerswarm"
    ]
  }
}
