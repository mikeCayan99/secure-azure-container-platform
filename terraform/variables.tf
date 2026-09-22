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

variable "container_app_name" {
  type        = string
  description = "Name of the Container App"
}

variable "container_image" {
  type        = string
  description = "Container image to deploy"
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "List of allowed IP ranges for the Container App"
}


