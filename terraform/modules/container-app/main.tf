resource "azurerm_container_app" "main" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = var.name
      image  = var.image
      cpu    = 0.25
      memory = "0.5Gi"
    }
    min_replicas = 0
    max_replicas = 1
  }

  ingress {
    external_enabled           = true
    target_port                = 8080
    transport                  = "auto"
    allow_insecure_connections = false

    traffic_weight {
      label           = "production"
      percentage      = 100
      latest_revision = true
    }


    dynamic "ip_security_restriction" {
      for_each = var.allowed_ip_ranges

      content {
        ip_address_range = ip_security_restriction.value
        action           = "Allow"
        name             = "allowed-ip-${ip_security_restriction.key}"
      }
    }
  }
}


