resource "azurerm_container_app_environment" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
}

