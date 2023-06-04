locals {
  network_name           = "${var.prefix}-vpc"
  gke_subnet_name        = "${var.prefix}-gke-subnet"
  master_auth_subnetwork = "${var.prefix}-gke-master-subnet"
  pods_range_name        = "${var.prefix}-gke-pods-ip-range"
  svc_range_name         = "${var.prefix}-gke-svc-ip-range"
}

data "http" "public_ip" {
  url = "http://ipv4.icanhazip.com"
}
