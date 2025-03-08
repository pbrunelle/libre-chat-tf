# LibreChat Infrastructure - main.tf
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_secret_manager_secret_version" "azure_openai_api_key" {
  secret = "AZURE_OPENAI_API_KEY_LIBRE_CHAT"
}

data "google_secret_manager_secret_version" "aws_access_key_id" {
  secret = "BEDROCK_AWS_ACCESS_KEY_ID_LIBRE_CHAT"
}

data "google_secret_manager_secret_version" "aws_secret_access_key" {
  secret = "BEDROCK_AWS_SECRET_ACCESS_KEY_LIBRE_CHAT"
}

data "google_secret_manager_secret_version" "gemini_api_key" {
  secret = "GEMINI_API_KEY_LIBRE_CHAT"
}

resource "local_file" "startup_script" {
  content = templatefile("${path.module}/startup-script.tpl", {
    azure_openai_api_key      = data.google_secret_manager_secret_version.azure_openai_key.secret_data,
    aws_access_key_id         = data.google_secret_manager_secret_version.bedrock_access_key.secret_data,
    aws_secret_access_key     = data.google_secret_manager_secret_version.bedrock_secret_key.secret_data,
    gemini_api_key            = data.google_secret_manager_secret_version.gemini_api_key.secret_data
  })
  filename        = "${path.module}/generated-startup-script.sh"
  file_permission = "0644"
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

resource "google_service_account" "librechat_sa" {
  account_id   = "librechat-service-account"
  display_name = "LibreChat Service Account"
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.librechat_sa.email}"
}

# Create the LibreChat VM instance
resource "google_compute_instance" "librechat" {
  name         = "librechat-server"
  machine_type = var.machine_type
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
  metadata_startup_script = local_file.startup_script.content
  service_account {
    email  = google_service_account.librechat_sa.email
    scopes = ["cloud-platform"]
  }
  allow_stopping_for_update = true
}

output "librechat_ip" {
  value = google_compute_instance.librechat.network_interface[0].access_config[0].nat_ip
}
