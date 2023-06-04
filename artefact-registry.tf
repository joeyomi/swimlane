resource "google_artifact_registry_repository" "artifact_registry_docker" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.prefix}-docker"
  description   = "${var.prefix} docker repository"
  format        = "DOCKER"
}

resource "google_storage_bucket" "build_files" {
  project                     = var.project_id
  location                    = "US"
  name                        = "${var.project_id}-build-files"
  uniform_bucket_level_access = true
  force_destroy               = true
  storage_class               = "STANDARD"
}

data "archive_file" "build_files" {
  type        = "zip"
  source_dir  = "${path.module}/include/devops-practical"
  output_path = "./build_files.zip"
}

resource "time_static" "build_files_update" {
  triggers = {
    build_files = data.archive_file.build_files.id
  }
}

resource "google_storage_bucket_object" "build_files" {
  name   = "build_files_${time_static.build_files_update.triggers.build_files}.zip"
  bucket = google_storage_bucket.build_files.name
  source = data.archive_file.build_files.output_path
}

resource "null_resource" "build_image" {
  triggers = {
    build_files_update = time_static.build_files_update.triggers.build_files
  }

  provisioner "local-exec" {
    command = "gcloud builds submit \"gs://${google_storage_bucket_object.build_files.bucket}/${google_storage_bucket_object.build_files.output_name}\" --tag=${google_artifact_registry_repository.artifact_registry_docker.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.artifact_registry_docker.name}/node:latest  --tag=${google_artifact_registry_repository.artifact_registry_docker.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.artifact_registry_docker.name}/node:${time_static.build_files_update.triggers.build_files} --project=${var.project_id}"
  }
}
