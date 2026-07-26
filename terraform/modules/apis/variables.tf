variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "services" {
  type        = set(string)
  description = "Google APIs to enable."
}

