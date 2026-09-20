module "resource_group" {
  source = "./modules/resource-group"

  name     = var.name
  location = var.location
}

