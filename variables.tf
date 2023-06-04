variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for the persistent volumes and GKE cluster"
  default     = "us-central1"
}

variable "prefix" {
  description = "Prefix to prepend to resources"
  type        = string
  default     = ""
}

variable "enabled-apis" {
  description = "Google Cloud API's to enable on the project."
  type        = list(string)
  default     = []
}

variable "dns_zone_name" {
  description = "Google Cloud DNS Managed Zone to create DNS records in."
  type        = string
  default     = ""
}

variable "dns_zone_project_id" {
  description = "Project ID of the Google Cloud DNS Managed Zone."
  type        = string
  default     = ""
}
