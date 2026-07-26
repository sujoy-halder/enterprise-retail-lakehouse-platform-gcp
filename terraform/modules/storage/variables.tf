variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "regions" { type = list(string) }
variable "kms_key_id" { type = string }
variable "force_destroy" { type = bool }
variable "labels" {
  type    = map(string)
  default = {}
}
variable "data_service_account_email" { type = string }
variable "composer_service_account_email" { type = string }

