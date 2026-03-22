# Proxmox connection (supply via env vars or .auto.tfvars)
variable "pm_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

# VM-specific vars (safe to override)
variable "target_node" {
  description = "Proxmox node to deploy to"
  type        = string
  default     = "proxmox"
}

variable "vm_template" {
  description = "Cloud-init template to clone"
  type        = string
  default     = "vm100"
}

variable "host_address_prefix" {
  description = "IP address prefix for VMs (e.g. '192.168.1')"
  type        = string
}

variable "pihole_password" {
  description = "Password for Pi-hole web interface"
  type        = string
  sensitive   = true
}

variable "nextcloud_db_password" {
  type      = string
  sensitive = true
}

variable "nextcloud_admin_user" {
  type    = string
  default = "admin"
}

variable "nextcloud_admin_password" {
  type      = string
  sensitive = true
}
