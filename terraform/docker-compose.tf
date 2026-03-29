locals {
  docker_compose = templatefile("${path.module}/docker/docker-compose.yaml.tftpl", {
    pihole_password          = var.pihole_password
    docker_host              = local.docker_host
    proxmox_url              = local.proxmox_url
    nextcloud_db_password    = var.nextcloud_db_password
    nextcloud_admin_user     = var.nextcloud_admin_user
    nextcloud_admin_password = var.nextcloud_admin_password
  })
}

# Write rendered content to a local temp file
resource "local_file" "docker_compose_rendered" {
  content  = local.docker_compose
  filename = "${path.module}/.rendered/docker-compose.yml"
}

resource "terraform_data" "docker_compose_sync" {
  triggers_replace = {
    compose_hash  = filemd5("${path.module}/docker/docker-compose.yaml.tftpl")
    homepage_hash = filemd5("${path.module}/docker/homepage/services.yaml")
  }

  depends_on = [terraform_data.provision_docker_host]

  connection {
    type        = "ssh"
    user        = "debian"
    private_key = file(local.ssh_path)
    host        = local.docker_host.ip_address
  }

  provisioner "file" {
    source      = local_file.docker_compose_rendered.filename
    destination = "/opt/docker/docker-compose.yml"
  }
  provisioner "file" {
    source      = "${path.module}/docker/homepage/"
    destination = "/opt/homepage/config"
  }
  provisioner "remote-exec" {
    inline = [
      "cd /opt/docker && docker compose up -d --no-recreate"
    ]
  }
}
