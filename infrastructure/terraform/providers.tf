terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-itext-pdf-demo"
    storage_account_name = "stitextpdftfstate2"
    container_name       = "tfstate"
    key                  = "itext-pdf-service.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  use_oidc            = true
  storage_use_azuread = true
}

provider "azapi" {
  use_oidc = true
}
