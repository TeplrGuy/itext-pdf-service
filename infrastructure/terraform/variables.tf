variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westus3"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-itext-pdf-demo"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "asp-itext-pdf-demo"
}

variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
  default     = "itext-pdf-service-demo"
}

variable "playwright_workspace_name" {
  description = "Name of the Playwright Testing workspace"
  type        = string
  default     = "pwitextpdfdemo"
}

variable "playwright_storage_name" {
  description = "Name of the storage account for Playwright Workspace reporting"
  type        = string
  default     = "stpwitextpdfreport"
}

variable "dotnet_version" {
  description = ".NET version for the App Service"
  type        = string
  default     = "10.0"
}

variable "github_actions_sp_object_id" {
  description = "Object ID of the GitHub Actions service principal (OIDC)"
  type        = string
  default     = "0766e7c6-0c6c-475f-9bb0-227b979df260"
}
