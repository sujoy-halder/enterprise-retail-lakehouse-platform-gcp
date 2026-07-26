variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "region" { type = string }
variable "network_id" { type = string }
variable "subnetwork_id" { type = string }
variable "composer_service_account_email" { type = string }
variable "environment_size" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}

