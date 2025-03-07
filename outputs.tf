# LibreChat Infrastructure - outputs.tf
output "librechat_ip_address" {
  value       = google_compute_instance.librechat.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the LibreChat server"
}

output "librechat_url" {
  value       = "http://${google_compute_instance.librechat.network_interface[0].access_config[0].nat_ip}:3080"
  description = "The URL to access LibreChat"
}

output "ssh_command" {
  value       = "gcloud compute ssh --project ${var.project_id} --zone ${var.zone} librechat-server"
  description = "Command to SSH into the LibreChat server"
}
