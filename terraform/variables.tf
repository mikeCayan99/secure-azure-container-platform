variable "location" {
  type        = string
  description = "Location of the resource group"
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "rg-secure-azure-container-platform"
}

variable "container_app_environment_name" {
  type        = string
  description = "Name of the Container App Environment"
  default     = "cae-secure-azure-container-platform"
}


