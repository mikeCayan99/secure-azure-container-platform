module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
}

module "container_app_environment" {
  source = "./modules/container-app-environment"

  name                = var.container_app_environment_name
  location            = var.location
  resource_group_name = module.resource_group.resource_group
}


