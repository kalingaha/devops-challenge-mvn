provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.repo_name
  description   = "Artifact Registry for devops-challenge"
  format        = "DOCKER"
}

resource "google_service_account" "cloudrun_sa" {
  account_id   = var.service_account_name
  display_name = "Cloud Run least-privilege SA"
}

resource "google_project_iam_member" "run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "allUsers"
}

resource "google_cloud_run_service" "devops_challenge" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.image_url
      }
      service_account_name = google_service_account.cloudrun_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "0"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_member" "allow_all" {
  location    = google_cloud_run_service.devops_challenge.location
  project     = var.project_id
  service     = google_cloud_run_service.devops_challenge.name
  role        = "roles/run.invoker"
  member      = "allUsers"
}

