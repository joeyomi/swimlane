module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  version    = "~> 26"
  project_id = var.project_id

  name                            = "${var.prefix}-cluster"
  description                     = "${var.prefix} cluster"
  region                          = var.region
  regional                        = true
  zones                           = ["${var.region}-a", "${var.region}-b"]
  network                         = local.network_name
  subnetwork                      = local.gke_subnet_name
  ip_range_pods                   = local.pods_range_name
  ip_range_services               = local.svc_range_name
  horizontal_pod_autoscaling      = true
  enable_vertical_pod_autoscaling = true
  enable_private_endpoint         = false
  enable_private_nodes            = true
  release_channel                 = "REGULAR"
  master_ipv4_cidr_block          = "192.168.128.0/28"

  master_authorized_networks = [
    {
      cidr_block   = "10.60.0.0/17"
      display_name = "VPC"
    },
    {
      cidr_block   = "${chomp(data.http.public_ip.body)}/32"
      display_name = "Caller's IP"
    }
  ]

  depends_on = [
    module.vpc, google_compute_router.router
  ]
}

resource "google_artifact_registry_repository_iam_member" "gke" {
  project    = google_artifact_registry_repository.artifact_registry_docker.project
  location   = google_artifact_registry_repository.artifact_registry_docker.location
  repository = google_artifact_registry_repository.artifact_registry_docker.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.gke.service_account}"
}


/* 
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-public-cluster"
  version = "~> 26"
  project_id = var.project_id

  name                            = "${var.prefix}-cluster"
  description                     = "${var.prefix} cluster"
  region                          = var.region
  regional                        = true
  zones                           = ["${var.region}-a", "${var.region}-b"]
  network                         = local.network_name
  subnetwork                      = local.gke_subnet_name
  ip_range_pods                   = local.pods_range_name
  ip_range_services               = local.svc_range_name
  horizontal_pod_autoscaling      = true
  enable_vertical_pod_autoscaling = true
  release_channel                 = "REGULAR"
  network_tags                    = [ "${var.prefix}-cluster"]
}
 */