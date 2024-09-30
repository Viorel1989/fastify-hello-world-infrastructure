# Configure the required provider and version
terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113"
    }
  }
  backend "azurerm" {}
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
