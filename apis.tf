resource "google_project_service" "enable-apis" {
  for_each = toset(var.enabled-apis)
  project  = var.project_id

  service            = each.value
  disable_on_destroy = false

  timeouts {
    create = "30m"
    update = "40m"
  }
}
