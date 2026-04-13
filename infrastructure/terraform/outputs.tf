output "app_service_url" {
  description = "URL of the deployed App Service"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "app_service_name" {
  description = "Name of the App Service for deployment"
  value       = azurerm_linux_web_app.main.name
}

output "playwright_service_url" {
  description = "Playwright Testing workspace WebSocket URL for browser connections"
  value       = "${replace(azapi_resource.playwright_workspace.output.properties.dataplaneUri, "https://", "wss://")}/browsers"
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}
