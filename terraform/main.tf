provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_project_metadata" "appuser1_key" {
  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}appuser1:${file(var.public_key_path)}appuser2:${file(var.public_key_path)}"
  }
}

resource "google_compute_instance" "puma" {
  name         = "puma-${count.index}"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  count        = "${var.count}"

  # Init boot disk
  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  # Init network_interface
  network_interface {
    network = "default"
    access_config {
    }
  }

 # metadata {
 #   ssh-keys = "appuser:${file(var.public_key_path)}"
 # }

  tags = ["reddit-app", "puma"]

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

resource "google_compute_firewall" "puma_default_filewall" {
  name = "puma-default-filewall"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["reddit-app"]
}
