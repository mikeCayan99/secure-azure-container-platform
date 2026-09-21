output "resource_group_name" {
  value = module.resource_group.resource_group
}

output "resource_group_location" {
  value = module.resource_group.location
}

output "container_app_environment_name" {
  value = module.container_app_environment.name
}

output "container_app_environment_location" {
  value = module.container_app_environment.location
}

output "container_app_environment_id" {
  value = module.container_app_environment.id
}

output "container_app_id" {
  value = module.container_app.container_app_id
}

output "container_app_name" {
  value = module.container_app.container_app_name
}