resource "proxmox_vm_qemu" "docker_host" {
  depends_on = [terraform_data.create_vm_template]

  name               = local.docker_host.name
  target_node        = var.target_node
  clone              = local.vm_template.name
  start_at_node_boot = true # start VM when Proxmox node boots
  full_clone         = true
  os_type            = "126"
  agent              = 0

  agent_timeout = 60

  cpu {
    cores   = 4
    sockets = 1
    type    = "host"
  }

  memory = 8192

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  disk {
    slot     = "scsi0"
    size     = local.docker_host.disk_size
    type     = "disk"
    storage  = "local-zfs"
    iothread = true
  }

  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = "local-zfs"
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-init config — injected at first boot
  ipconfig0  = "ip=${local.docker_host.ip_address}/24,gw=${var.host_address_prefix}.1"
  nameserver = "1.1.1.1"
  ciuser     = "debian"
  sshkeys    = trimspace(file("${local.ssh_path}.pub")) # Public key injected into VM

  lifecycle {
    ignore_changes = [network, disk, disks, startup_shutdown]
  }
}

# After qm clone, immediately attach cloudinit drive
resource "terraform_data" "attach_cloudinit_drive" {
  depends_on = [proxmox_vm_qemu.docker_host]

  triggers_replace = {
    vm_id = proxmox_vm_qemu.docker_host.id

    # runs again if VM is recreated
    vm_hash = sha256(jsonencode(proxmox_vm_qemu.docker_host))
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = var.proxmox_url      # e.g. "192.168.1.10"
    private_key = file(local.ssh_path) # e.g. "~/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "VMID=$(qm list | grep ${proxmox_vm_qemu.docker_host.name} | awk '{print $1}')",
      "echo \"Fixing VM $VMID\"",
      "qm stop $VMID || true",
      "sleep 5",

      # Attach disk if still unused (Telmate 3.0.x bug)
      "DISK=$(qm config $VMID | grep '^unused0' | awk '{print $2}')",
      "if [ -n \"$DISK\" ]; then echo 'Attaching unused disk...' && qm set $VMID --scsi0 $DISK; fi",

      # Attach cloudinit drive if missing
      "qm config $VMID | grep -q '^ide2' || qm set $VMID --ide2 local-zfs:cloudinit",

      # Resize disk to target size
      "qm resize $VMID scsi0 ${local.docker_host.disk_size}",

      # Enable cloud init
      "qm set $VMID --agent enabled=1",

      # Ensure correct boot order
      "qm set $VMID --boot order=scsi0",

      # Regenerate cloud-init with all vars (ip, sshkeys, user etc)
      "qm cloudinit update $VMID",

      # Start VM
      "qm start $VMID",

      # Wait for guest agent to respond (means cloud-init finished)
      "echo 'Waiting for guest agent...'",
      "for i in $(seq 1 20); do qm agent $VMID ping > /dev/null 2>&1 && echo 'Guest agent up!' && break || echo \"Attempt $i/20...\" && sleep 5; done",

      "qm agent $VMID ping || (echo 'ERROR: VM did not boot in time' && exit 1)",
    ]
  }
}

resource "null_resource" "provision_docker_host" {
  depends_on = [
    terraform_data.attach_cloudinit_drive,
    proxmox_vm_qemu.docker_host
  ]

  triggers = {
    vm_id       = proxmox_vm_qemu.docker_host.id
    script_hash = filesha256(local.provision_script_path)
  }

  provisioner "file" {
    source      = local.provision_script_path
    destination = "/tmp/provision.sh"
  }

  # You need to create an .env file with any variables your provisioning script needs
  # For pihole, I have FTLCONF_webserver_api_password
  provisioner "file" {
    source      = "${path.module}/docker/.env"
    destination = "/tmp/docker.env"
  }

  connection {
    type        = "ssh"
    user        = "debian"
    host        = local.docker_host.ip_address
    private_key = file(local.ssh_path)

    # bastion_host        = var.proxmox_url
    # bastion_user        = "root"
    # bastion_private_key = file(local.ssh_path)
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo /tmp/provision.sh"
    ]
  }
}
