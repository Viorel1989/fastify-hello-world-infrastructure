variable "resource_group_name" {
  description = "The name of the Azure Resource Group"
  type        = string
  default     = "fastifyResourceGroup"
}

variable "ssh_user" {
  description = "The username for the Virtual Machine"
  type        = string
  default     = "viorel"
}

variable "ssh_key" {
  description = "The path to the SSH public key used to authenticate the Virtual Machine"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_allowed_ips" {
  description = "The list of IP addresses allowed to connet to the Virtual Machine"
  type        = list(string)
  default     = []
}

variable "source_image_name" {
  description = "The name of the image used to create the Virtual Machine"
  type        = string
  default     = "fastifyVM-v1.1.2"
}

variable "service_port" {
  description = "The port number for the application."
  type        = number
  default     = 3000
}
