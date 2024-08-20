# Configure the required provider and version
terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113"
    }
  }
  backend "azurerm" {
    resource_group_name  = "fastifyResourceGroup"
    storage_account_name = "tfstateb7000d6c"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
