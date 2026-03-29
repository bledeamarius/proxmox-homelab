resource "terraform_data" "create_vm_template" {
  triggers_replace = {
    template_id      = local.vm_template.id
    template_content = filemd5("${path.module}/scripts/vm_template.sh") # Re-run if the provisioning script changes
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = local.proxmox_url    # e.g. "192.168.1.10"
    private_key = file(local.ssh_path) # e.g. "~/.ssh/id_rsa"
  }

  # Upload script
  provisioner "file" {
    source      = "${path.module}/scripts/vm_template.sh"
    destination = "/tmp/vm_template.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/vm_template.sh",
      "/tmp/vm_template.sh ${local.vm_template.id} ${local.vm_template.name} ${local.vm_template.cpus} ${local.vm_template.memory} ${local.vm_template.disk_size}"
    ]
  }
}
