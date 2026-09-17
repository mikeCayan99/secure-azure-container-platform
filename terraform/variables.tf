variable "location" {
  type        = string
  description = "Location of the resource group"
  default     = "westeurope"
}

variable "tags" {
  type = map(string)

  default = {
    project     = "secure-azure-container-platform"
    environment = "dev"
    managed_by  = "terraform"
  }
}