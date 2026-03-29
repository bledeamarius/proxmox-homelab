# Copy docker-compose.yml to VM
resource "terraform_data" "docker_compose_sync" {
  triggers_replace = {
    compose_hash = filemd5("${path.module}/docker/docker-compose.yaml")
  }

  depends_on = [null_resource.provision_docker_host]

  connection {
    type        = "ssh"
    user        = "debian"
    private_key = file(local.ssh_path)
    host        = local.docker_host.ip_address
    # bastion_host = "192.168.6.10"
    # bastion_user = "root"
  }

  provisioner "file" {
    source      = "${path.module}/docker/docker-compose.yaml"
    destination = "/opt/docker/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/docker && docker compose up -d --no-recreate"
    ]
  }
}
