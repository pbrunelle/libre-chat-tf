# LibreChat Infrastructure - main.tf
provider "google" {
  project = "gen-lang-client-0901067425"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# Allow traffic on port 3080
resource "google_compute_firewall" "allow_librechat" {
  name    = "allow-librechat"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["3080"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Create the LibreChat VM instance
resource "google_compute_instance" "librechat" {
  name         = "librechat-server"
  machine_type = "e2-small"  # 2 vCPUs, 2 GB memory
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20250213"
      size  = 10
    }
  }
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  metadata_startup_script = file("${path.module}/startup-script.sh")
  service_account {
    scopes = ["cloud-platform"]
  }
  allow_stopping_for_update = true
}

output "librechat_ip" {
  value = google_compute_instance.librechat.network_interface[0].access_config[0].nat_ip
}
