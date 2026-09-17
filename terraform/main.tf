resource "azurerm_resource_group" "main" {
  name     = "rg-secure-azure-container-platform"
  location = var.location
  tags     = var.tags
}
