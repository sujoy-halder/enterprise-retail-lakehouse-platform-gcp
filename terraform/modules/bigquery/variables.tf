variable "project_id" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "kms_key_id" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}

