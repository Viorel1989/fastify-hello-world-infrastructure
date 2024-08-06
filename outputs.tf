output "service_endpoint" {
  value = "https//${azurerm_public_ip.this.ip_address}:${local.service_port}"
}
