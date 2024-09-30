# Define the resource group
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Define virtual network - used for communication inside the application services
resource "azurerm_virtual_network" "this" {
  name                = data.azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

# Define subnet - a range of IP addresses in the virtual network
resource "azurerm_subnet" "private" {
  name                 = "${data.azurerm_resource_group.this.name}-private"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Define public IP - assigns a public IP address for internet access
resource "azurerm_public_ip" "this" {
  name                = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Dynamic"
}

# Define network interface - allows the VM to communicate within the virtual network
resource "azurerm_network_interface" "private" {
  name                = "${data.azurerm_resource_group.this.name}-private"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "private"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}


# Define network interface for the public IP - associates the public IP with the network interface
resource "azurerm_network_interface" "public" {
  name                = "${data.azurerm_resource_group.this.name}-public"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}


# Define the network security group to open port 3000
resource "azurerm_network_security_group" "default" {
  name                = "${data.azurerm_resource_group.this.name}-default"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  #trivy:ignore:avd-azu-0047
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = var.service_port
    source_address_prefix      = "*"
    destination_port_range     = var.service_port
    destination_address_prefix = azurerm_network_interface.public.private_ip_address
  }

  dynamic "security_rule" {
    for_each = var.ssh_allowed_ips

    content {
      access                     = "Allow"
      direction                  = "Inbound"
      name                       = "ssh-${security_rule.value}"
      priority                   = 200 + security_rule.key
      protocol                   = "TCP"
      source_port_range          = "22"
      source_address_prefix      = security_rule.value
      destination_port_range     = "22"
      destination_address_prefix = azurerm_network_interface.public.private_ip_address
    }

  }
}

# Associate the network security group with the network interface
resource "azurerm_network_interface_security_group_association" "default" {
  network_interface_id      = azurerm_network_interface.private.id
  network_security_group_id = azurerm_network_security_group.default.id
}

# Define the source image using the custom image ID
data "azurerm_image" "this" {
  name                = var.source_image_name
  resource_group_name = data.azurerm_resource_group.this.name
}

# Define the virtual machine - creates the VM using the specified image and configuration
resource "azurerm_linux_virtual_machine" "fastifyVM" {
  name                = "fastifyVM"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  size                = "Standard_B1S"
  admin_username      = var.ssh_user

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_key)
  }

  network_interface_ids = [
    azurerm_network_interface.public.id,
    azurerm_network_interface.private.id
  ]

  source_image_id = data.azurerm_image.this.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(<<-EOT
    #!/bin/bash

    # Modify the systemd service file to include the environment variable
    mkdir -p /etc/systemd/system/fastify-hello-world.service.d
    echo "[Service]" > /etc/systemd/system/fastify-hello-world.service.d/env.conf
    echo "Environment=PORT=${var.service_port}" >> /etc/systemd/system/fastify-hello-world.service.d/env.conf

    # Reload systemd to apply changes
    systemctl daemon-reload
    systemctl restart fastify-hello-world.service
  EOT
  )

}
