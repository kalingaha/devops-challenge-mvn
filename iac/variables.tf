variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "repo_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "devops-repo"
}

variable "service_account_name" {
  description = "Name for the Cloud Run service account"
  type        = string
  default     = "devops-cloudrun-sa"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "devops-challenge"
}

variable "image_url" {
  description = "Fully qualified image URI"
  type        = string
}

