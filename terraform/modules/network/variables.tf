variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "region" { type = string }
variable "secondary_region" { type = string }
variable "primary_cidr" { type = string }
variable "secondary_cidr" { type = string }
variable "pods_cidr" { type = string }
variable "services_cidr" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}

