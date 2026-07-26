variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "github_owner" { type = string }
variable "github_repo" { type = string }
variable "deploy_service_account" { type = string }
variable "artifact_repository_id" { type = string }
variable "terraform_service_roles" { type = list(string) }
variable "labels" {
  type    = map(string)
  default = {}
}

