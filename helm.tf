locals {
  image_repository = "${google_artifact_registry_repository.artifact_registry_docker.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.artifact_registry_docker.name}/node"
  image_tag        = time_static.build_files_update.triggers.build_files
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }
}

resource "helm_release" "application" {
  name      = "application"
  chart     = "${path.module}/include/helm/chart"
  namespace = "default"

  values = [<<-EOF
  # Mongo
  mongodb:
    replicaCount: 1
    image:
      repository: mongo
      tag: latest
      pullPolicy: IfNotPresent
    resources:
      cpu: 1024m
      memory: 2048Mi
      storage: 30Gi
    service:
      port: 27017
      targetPort: 27017
      type: ClusterIP
    adminCredentials:
      username: admin
      password: admin123

  # FRONT END
  frontend:
    replicaCount: 1
    image:
      repository: ${local.image_repository} # mongo-express
      tag: ${local.image_tag} # latest
      pullPolicy: IfNotPresent
    resources:
      requests:
        cpu: 200m
        memory: 300Mi
    livenessProbe:
      initialDelaySeconds: 30
      periodSeconds: 10
    service:
      name: frontend
      port: 80
      targetPort: 3000 #8081
      type: ClusterIP

  # INGRESS
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.global-static-ip-name: ${google_compute_global_address.frontend.name}
      kubernetes.io/ingress.class: gce
      networking.gke.io/managed-certificates: ${var.prefix}-managed-cert
    hosts:
      - host: ${trimsuffix(google_dns_record_set.frontend.name, ".")}
        paths:
          - /
      - host: ${trimsuffix(google_dns_record_set.frontend.name, ".")}
        paths:
          - /*

  EOF
  ]
}


#
# DNS
#
resource "google_compute_global_address" "frontend" {
  project = var.project_id
  name    = "${var.prefix}-frontend"
}

resource "google_dns_record_set" "frontend" {
  project      = var.dns_zone_project_id
  managed_zone = data.google_dns_managed_zone.public.name
  name         = "frontend.${data.google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.frontend.address]
}

#
# SSL Certificate
#
resource "kubernetes_manifest" "ssl" {
  depends_on = [google_project_service.enable-apis]

  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"

    metadata = {
      name      = "${var.prefix}-managed-cert"
      namespace = "default"
    }

    spec = {
      domains = [
        trimsuffix(google_dns_record_set.frontend.name, "."),
      ]
    }
  }
}

data "google_dns_managed_zone" "public" {
  project = var.dns_zone_project_id
  name    = var.dns_zone_name
}
