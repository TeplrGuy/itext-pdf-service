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
