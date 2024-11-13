output "service_endpoint" {
  value = "https//${azurerm_public_ip.vm_public_ip.ip_address}:${var.service_port}"
}
# output "lb_public_ip" {
#   value = azurerm_public_ip.lb_public_ip.ip_address
# }


output "public_ip_address" {
  value = "http://${azurerm_public_ip.lb_public_ip.ip_address}"
}
