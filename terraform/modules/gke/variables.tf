variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "region" { type = string }
variable "network_self_link" { type = string }
variable "subnetwork_self_link" { type = string }
variable "pods_secondary_range" { type = string }
variable "services_secondary_range" { type = string }
variable "master_ipv4_cidr_block" { type = string }
variable "authorized_cidr_blocks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}
variable "node_service_account_email" { type = string }
variable "min_nodes" { type = number }
variable "max_nodes" { type = number }
variable "deletion_protection" { type = bool }
variable "labels" {
  type    = map(string)
  default = {}
}

