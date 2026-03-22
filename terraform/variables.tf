# Proxmox connection (supply via env vars or .auto.tfvars)
variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

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

variable "proxmox_url" {
  description = "Proxmox IP for SSH access during provisioning"
  type        = string
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