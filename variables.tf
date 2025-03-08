# LibreChat Infrastructure - variables.tf
variable "project_id" {
  description = "The GCP project id"
  type        = string
}

variable "machine_type" {
  description = "The machine type for the VM instance"
  type        = string
  default     = "e2-small"
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to deploy the VM"
  type        = string
  default     = "us-central1-a"
}
