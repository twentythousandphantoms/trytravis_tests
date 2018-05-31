resource "google_compute_firewall" "firewall_ssh" {
  name        = "default-allow-ssh"
  network     = "default"
  target_tags = ["reddit-app", "reddit-db"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = "${var.source_ranges}"
}

resource "google_compute_firewall" "firewall_ssh_deny" {
  name        = "default-deny-ssh"
  network     = "default"
  target_tags = ["reddit-app", "reddit-db"]

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 10000
}
