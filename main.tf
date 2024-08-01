# Configure the required provider and version
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
    backend "azurerm" {
      resource_group_name  = "fastifyResourceGroup"
      storage_account_name = "tffastifystate5606"
      container_name       = "tffastifystate"
      key                  = "terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

#Resource Group
#VM image
#Virtual Network
#Subnet
#Network Security Group
#Public IP address
#Network Interface
#Virtual Machine
#OS Disk
#Boot Diagnostic Storage(optional)


#TBD: service principal creation

# Define the resource group
data "azurerm_resource_group" "fastifyResourceGroup" {
  name = "fastifyResourceGroup"
}

data "azurerm_image" "fastify-image" {
  name_regex          = "^fastifyVM-v([0-9]+\\.[0-9]+\\.[0-9]+)$"
  resource_group_name = "fastifyResourceGroup"
}

output "image_id" {
  value = data.azurerm_image.fastify-image.id
}

# Define virtual network - used for communication inside the application services
resource "azurerm_virtual_network" "fastify-network" {
  name                = "fastify-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.fastifyResourceGroup.location
  resource_group_name = data.azurerm_resource_group.fastifyResourceGroup.name
}

# Define subnet - a range of IP addresses in the virtual network
resource "azurerm_subnet" "fastify-internal-network" {
  name                 = "fastify-internal-network"
  resource_group_name  = data.azurerm_resource_group.fastifyResourceGroup.name
  virtual_network_name = azurerm_virtual_network.fastify-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Define network interface - allows the VM to communicate within the virtual network
resource "azurerm_network_interface" "fastify-nic" {
  name                = "fastify-nic"
  location            = data.azurerm_resource_group.fastifyResourceGroup.location
  resource_group_name = data.azurerm_resource_group.fastifyResourceGroup.name

  ip_configuration {
    name                          = "fastify-internal-ip-config"
    subnet_id                     = azurerm_subnet.fastify-internal-network.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Define public IP - assigns a public IP address for internet access
resource "azurerm_public_ip" "fastify-pub-ip" {
  name                = "fastify-ip"
  location            = data.azurerm_resource_group.fastifyResourceGroup.location
  resource_group_name = data.azurerm_resource_group.fastifyResourceGroup.name
  allocation_method   = "Dynamic"
}

# Define network interface for the public IP - associates the public IP with the network interface
resource "azurerm_network_interface" "fastify-pub-nic" {
  name                = "fastify-pub-nic"
  location            = data.azurerm_resource_group.fastifyResourceGroup.location
  resource_group_name = data.azurerm_resource_group.fastifyResourceGroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.fastify-internal-network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.fastify-pub-ip.id
  }
}


# Define the network security group to open port 3000
resource "azurerm_network_security_group" "fastify-sg" {
  name                = "fastify-security-group"
  location            = data.azurerm_resource_group.fastifyResourceGroup.location
  resource_group_name = data.azurerm_resource_group.fastifyResourceGroup.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate the network security group with the network interface
resource "azurerm_network_interface_security_group_association" "fastify-sg-association" {
  network_interface_id      = azurerm_network_interface.fastify-pub-nic.id
  network_security_group_id = azurerm_network_security_group.fastify-sg.id
}


# Define the virtual machine - creates the VM using the specified image and configuration
resource "azurerm_linux_virtual_machine" "fastify-hello-world" {
  name                = "fastify-hello-world"
  resource_group_name = data.azurerm_resource_group.fastifyResourceGroup.name
  location            = data.azurerm_resource_group.fastifyResourceGroup.location
  size                = "Standard_B1S"
  admin_username      = "viorel"
  network_interface_ids = [
    azurerm_network_interface.fastify-pub-nic.id,
  ]
  admin_ssh_key {
    username   = "viorel"
    public_key = file("~/.ssh/id_rsa_fastify.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  # Define the source image using the custom image ID
  source_image_id = data.azurerm_image.fastify-image.id
}