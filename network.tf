module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 7.0"

  project_id   = var.project_id
  network_name = local.network_name
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = local.gke_subnet_name
      subnet_ip             = "10.0.0.0/17"
      subnet_region         = var.region
      subnet_private_access = null //"true"
      subnet_flow_logs      = "false"
      description           = "GKE subnet"
    },
    {
      subnet_name           = local.master_auth_subnetwork
      subnet_ip             = "10.60.0.0/17"
      subnet_region         = var.region
      subnet_private_access = null //"true"
      subnet_flow_logs      = "false"
      description           = "Master auth subnet"
    }
  ]

  secondary_ranges = {
    (local.gke_subnet_name) = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = local.svc_range_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

resource "google_compute_router" "router" {
  project = var.project_id
  region  = var.region

  name    = "nat-router"
  network = module.vpc.network_id

  bgp {
    asn                = "64514"
    keepalive_interval = "20"
  }
  depends_on = [module.vpc.subnets_names]
}

resource "google_compute_router_nat" "nat" {
  project = var.project_id
  region  = var.region

  name                                = "nat"
  router                              = google_compute_router.router.name
  nat_ip_allocate_option              = "AUTO_ONLY"
  nat_ips                             = []
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                    = "64"
  udp_idle_timeout_sec                = "30"
  icmp_idle_timeout_sec               = "30"
  tcp_established_idle_timeout_sec    = "1200"
  tcp_transitory_idle_timeout_sec     = "30"
  enable_endpoint_independent_mapping = null
}