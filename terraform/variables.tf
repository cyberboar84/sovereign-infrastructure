variable "network_cidr" {
  description = "The CIDR block for the management network"
  type        = string
}

variable "gateway_ip" {
  description = "The IP address of the pfSense Gateway"
  type        = string
}

variable "dhcp_start" {
  description = "The start of the DHCP range"
  type        = string
}

variable "existing_nodes" {
  description = "Map of existing IPs"
  type        = map(string)
}

variable "new_infrastructure" {
  description = "Configuration for new nodes"
  type        = map(string)
}
