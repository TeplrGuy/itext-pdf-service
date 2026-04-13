# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# ---------------------------------------------------------------------------
# App Service Plan (Linux, F1)
# ---------------------------------------------------------------------------
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "F1"
}

# ---------------------------------------------------------------------------
# App Service (Blazor Server / .NET 10)
# ---------------------------------------------------------------------------
resource "azurerm_linux_web_app" "main" {
  name                = var.app_service_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  client_affinity_enabled                        = true
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  site_config {
    application_stack {
      dotnet_version = var.dotnet_version
    }
    always_on    = false
    ftps_state   = "FtpsOnly"
    http2_enabled = true
  }
}

# ---------------------------------------------------------------------------
# Playwright Testing Workspace (Azure Playwright Testing)
# ---------------------------------------------------------------------------
resource "azapi_resource" "playwright_workspace" {
  type      = "Microsoft.LoadTestService/playwrightWorkspaces@2025-09-01"
  name      = var.playwright_workspace_name
  parent_id = azurerm_resource_group.main.id
  location  = azurerm_resource_group.main.location

  body = {
    properties = {
      regionalAffinity = "Enabled"
      localAuth        = "Enabled"
    }
  }

  schema_validation_enabled = false
}
