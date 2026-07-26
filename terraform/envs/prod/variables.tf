variable "project_id" { type = string }
variable "prefix" {
  type    = string
  default = "retail-lakehouse"
}
variable "region" {
  type    = string
  default = "us-central1"
}
variable "secondary_region" {
  type    = string
  default = "us-east1"
}
variable "bigquery_location" {
  type    = string
  default = "us-central1"
}
variable "github_owner" { type = string }
variable "github_repo" { type = string }
variable "billing_alert_email" {
  type    = string
  default = ""
}
variable "deploy_composer" {
  type    = bool
  default = true
}
variable "primary_subnet_cidr" {
  type    = string
  default = "10.60.0.0/20"
}
variable "secondary_subnet_cidr" {
  type    = string
  default = "10.64.0.0/20"
}
variable "pods_cidr" {
  type    = string
  default = "10.68.0.0/14"
}
variable "services_cidr" {
  type    = string
  default = "10.72.0.0/20"
}
variable "master_ipv4_cidr_block" {
  type    = string
  default = "172.17.0.0/28"
}
variable "authorized_cidr_blocks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}
variable "github_deploy_roles" {
  type = list(string)
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
  type = map(string)
  default = {
    owner = "data-platform"
  }
}
