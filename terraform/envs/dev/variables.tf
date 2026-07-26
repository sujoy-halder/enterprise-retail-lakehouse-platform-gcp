variable "project_id" {
  description = "GCP project ID for this environment."
  type        = string
}

variable "prefix" {
  description = "Short resource prefix. Use lowercase letters, numbers, and hyphens."
  type        = string
  default     = "retail-lakehouse"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Primary GCP region."
  type        = string
  default     = "us-central1"
}

variable "secondary_region" {
  description = "Secondary GCP region for replicated lake buckets and DR-ready topology."
  type        = string
  default     = "us-east1"
}

variable "bigquery_location" {
  description = "BigQuery dataset location."
  type        = string
  default     = "us-central1"
}

variable "github_owner" {
  description = "GitHub organization or user that owns the deployment repo."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name authorized to deploy."
  type        = string
}

variable "billing_alert_email" {
  description = "Email for monitoring notifications. Leave empty to skip email channel creation."
  type        = string
  default     = ""
}

variable "deploy_composer" {
  description = "Whether to create Cloud Composer."
  type        = bool
  default     = true
}

variable "primary_subnet_cidr" {
  description = "CIDR for the primary regional subnet."
  type        = string
  default     = "10.40.0.0/20"
}

variable "secondary_subnet_cidr" {
  description = "CIDR for the secondary regional subnet."
  type        = string
  default     = "10.44.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range for GKE pods."
  type        = string
  default     = "10.48.0.0/14"
}

variable "services_cidr" {
  description = "Secondary range for GKE services."
  type        = string
  default     = "10.52.0.0/20"
}

variable "master_ipv4_cidr_block" {
  description = "Private CIDR block for the GKE control plane."
  type        = string
  default     = "172.16.0.0/28"
}

variable "authorized_cidr_blocks" {
  description = "CIDR blocks allowed to reach the private GKE control plane."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "github_deploy_roles" {
  description = "Project roles granted to the GitHub deploy service account."
  type        = list(string)
  default = [
    "roles/artifactregistry.writer",
    "roles/bigquery.admin",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/composer.admin",
    "roles/container.admin",
    "roles/iam.serviceAccountUser",
    "roles/pubsub.admin",
    "roles/secretmanager.secretAccessor",
    "roles/storage.admin"
  ]
}

variable "labels" {
  description = "Common labels."
  type        = map(string)
  default = {
    owner = "data-platform"
  }
}
