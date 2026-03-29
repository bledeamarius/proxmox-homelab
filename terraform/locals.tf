locals {
  ssh_path    = "~/.ssh/id"
  proxmox_url = "${var.host_address_prefix}.10"
  vm_template = {
    id        = 9009
    name      = "debian-12-template"
    cpus      = 2
    memory    = 2048
    disk_size = "10G"
  }

  provision_script_path = "${path.module}/scripts/provision.sh"

  docker_host = {
    name       = "docker-host"
    ip_address = "${var.host_address_prefix}.50"
    disk_size  = "40G"
  }
}