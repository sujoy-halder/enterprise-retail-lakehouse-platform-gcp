variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}
variable "publisher_service_accounts" { type = list(string) }
variable "subscriber_service_accounts" { type = list(string) }

