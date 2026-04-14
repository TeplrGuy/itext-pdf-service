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
  type      = "Microsoft.LoadTestService/playwrightWorkspaces@2026-02-01-preview"
  name      = var.playwright_workspace_name
  parent_id = azurerm_resource_group.main.id
  location  = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      regionalAffinity = "Enabled"
      localAuth        = "Enabled"
      reporting        = "Enabled"
      storageUri       = azurerm_storage_account.playwright_reporting.primary_blob_endpoint
    }
  }

  schema_validation_enabled = false
}

# ---------------------------------------------------------------------------
# Storage Account for Playwright Workspace Reporting
# ---------------------------------------------------------------------------
resource "azurerm_storage_account" "playwright_reporting" {
  name                            = var.playwright_storage_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  public_network_access_enabled   = true
  default_to_oauth_authentication = true

  blob_properties {
    cors_rule {
      allowed_origins    = ["https://trace.playwright.dev"]
      allowed_methods    = ["GET", "HEAD", "OPTIONS"]
      allowed_headers    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }
}

# ---------------------------------------------------------------------------
# RBAC: Workspace MI → Storage Blob Data Contributor on reporting storage
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "playwright_mi_storage" {
  scope                = azurerm_storage_account.playwright_reporting.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.playwright_workspace.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# ---------------------------------------------------------------------------
# RBAC: GitHub Actions SP → Storage Blob Data Contributor on reporting storage
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "github_sp_storage" {
  scope                = azurerm_storage_account.playwright_reporting.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.github_actions_sp_object_id
  principal_type       = "ServicePrincipal"
}

# ---------------------------------------------------------------------------
# RBAC: Current user → Storage Blob Data Contributor on reporting storage
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "user_storage" {
  scope                = azurerm_storage_account.playwright_reporting.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

# ---------------------------------------------------------------------------
# RBAC: Current user → Playwright Workspace Contributor
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "user_playwright" {
  scope                = azapi_resource.playwright_workspace.id
  role_definition_name = "Playwright Workspace Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

# ---------------------------------------------------------------------------
# RBAC: GitHub Actions SP → Playwright Workspace Contributor
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "github_sp_playwright" {
  scope                = azapi_resource.playwright_workspace.id
  role_definition_name = "Playwright Workspace Contributor"
  principal_id         = var.github_actions_sp_object_id
  principal_type       = "ServicePrincipal"
}

# ---------------------------------------------------------------------------
# Data source: current authenticated user
# ---------------------------------------------------------------------------
data "azurerm_client_config" "current" {}
