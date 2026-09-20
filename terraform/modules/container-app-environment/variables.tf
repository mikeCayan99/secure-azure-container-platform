variable "name" {
  type        = string
  description = "Name of the resource group"
  default     = "azure-container-app-environment"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}