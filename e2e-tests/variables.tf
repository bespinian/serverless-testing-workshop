variable "environment" {
  description = "The environment to deploy to"
  type        = string
  default     = "production"
}

variable "resource_suffix" {
  description = "A suffix to add to all resource names to prevent naming conflicts"
  type        = string
}

locals {
  application = "jokester"
}
