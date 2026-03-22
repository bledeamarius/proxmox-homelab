# homelab-infra

Infrastructure as Code for a self-hosted homelab running on Proxmox VE, managed with Terraform.

## Stack

- **Proxmox VE** — bare metal hypervisor
- **Terraform** — provisions VMs and manages infrastructure lifecycle
- **Docker + Docker Compose** — container runtime for self-hosted services
- **Cloud-init** — VM bootstrapping and configuration

## What It Does

- Creates a Debian 12 base template on Proxmox using `virt-customize` with `qemu-guest-agent` baked in
- Provisions a `docker-host` VM with a static IP via cloud-init
- Deploys Docker Compose services onto the VM via Terraform file provisioners
- Automatically re-provisions when infrastructure scripts or configs change (via file hash triggers)


