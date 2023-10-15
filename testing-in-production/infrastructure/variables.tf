variable "resource_suffix" {
  description = "A suffix to be added to all resource names to prevent conflicts"
  type        = string
}

locals {
  application = "canary"
}
