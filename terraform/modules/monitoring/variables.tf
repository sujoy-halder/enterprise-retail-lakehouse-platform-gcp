variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "notification_email" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}

