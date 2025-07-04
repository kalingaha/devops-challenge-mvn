output "cloud_run_url" {
  value = google_cloud_run_service.devops_challenge.status[0].url
}

