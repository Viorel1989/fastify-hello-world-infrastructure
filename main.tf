# Define the resource group
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

//////////////////////////////////

# Define the Public Load Balancer
resource "azurerm_lb" "public" {
  name                = "${data.azurerm_resource_group.this.name}-public-lb"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "Basic"

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

# Define the Backend Pool to link VMs
resource "azurerm_lb_backend_address_pool" "public" {
  name            = "${data.azurerm_resource_group.this.name}-backend-pool"
  loadbalancer_id = azurerm_lb.public.id
}

# Define a health probe to monitor the VM's health (e.g., checking port 80)
resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id     = azurerm_lb.public.id
  name                = "http-probe"
  protocol            = "Http"
  port                = 3000
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Define the load balancing rule
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.public.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 3000 # Port on the load balancer
  backend_port                   = 3000 # Port on the VM
  frontend_ip_configuration_name = "public-frontend"
  probe_id                       = azurerm_lb_probe.http_probe.id
}

# Associate the network interface with the backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vm_backend_association" {
  network_interface_id    = azurerm_network_interface.private.id
  ip_configuration_name   = "private"
  backend_address_pool_id = azurerm_lb_backend_address_pool.public.id
}



//////////////////////////////////

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
  allocation_method   = "Static"
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
# resource "azurerm_network_interface" "public" {
#   name                = "${data.azurerm_resource_group.this.name}-public"
#   location            = data.azurerm_resource_group.this.location
#   resource_group_name = data.azurerm_resource_group.this.name

#   ip_configuration {
#     name                          = "public"
#     subnet_id                     = azurerm_subnet.private.id
#     private_ip_address_allocation = "Dynamic"
#     # public_ip_address_id          = azurerm_public_ip.this.id
#   }
# }


# Define the network security group to open port 3000
resource "azurerm_network_security_group" "default" {
  name                = "${data.azurerm_resource_group.this.name}-default"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  # Rule to allow HTTP traffic from the Load Balancer
  security_rule {
    name                       = "Allow-LB-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_port_range     = var.service_port
    destination_address_prefix = "*"
  }

  # SSH access rules for specific IPs
  dynamic "security_rule" {
    for_each = var.ssh_allowed_ips

    content {
      access                     = "Allow"
      direction                  = "Inbound"
      name                       = "Allow-SSH-${security_rule.value}"
      priority                   = 200 + security_rule.key
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_range     = "22"
      destination_address_prefix = "*"
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
    # azurerm_network_interface.public.id,
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
