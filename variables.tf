variable "project_id" {
  type        = string
  description = "GCP project id"
}

variable "region" {
  type        = string
  description = "GCP region for the persistent volumes and GKE cluster"
  default     = "us-central1"
}

variable "prefix" {
  type    = string
  default = ""
}

variable "enabled-apis" {
  type    = list(string)
  default = []
}

variable "secret_accessors" {
  type    = list(string)
  default = []
}

variable "dns_zone_name" {

}

variable "dns_zone_project_id" {

}
