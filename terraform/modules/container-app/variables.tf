variable "name" {
  type        = string
  description = "Name of the Container App"
  default     = "mein-container-app"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "container_app_environment_id" {
  type        = string
  description = "ID of the Container App Environment"
}

variable "image" {
  type        = string
  description = "Container image to deploy"
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "List of allowed IP ranges for the Container App"
}



