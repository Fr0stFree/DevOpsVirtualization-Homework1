resource "yandex_vpc_network" "kittygram-network" {
  name = "kittygram-network"
}

resource "yandex_vpc_subnet" "kittygram-subnet" {
  name           = "kittygram-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.kittygram-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_security_group" "kittygram-security-group" {
  name        = "kittygram-security-group"
  description = "Default security group for kittygram site"
  network_id  = yandex_vpc_network.kittygram-network.id

  egress {
    description    = "Allow all outgoing traffic"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Allow SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "kittygram_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  filename        = "${path.module}/kittygram_ssh_key.pem"
  content         = tls_private_key.kittygram_ssh_key.private_key_openssh
  file_permission = "0600"
}

resource "yandex_compute_disk" "kittygram-boot-disk" {
  image_id = "fd8vmcue7aajpmeo39kk" # ubuntu 20-04
  name     = "kittygram-boot-disk"
  type     = "network-hdd"
  zone     = var.zone
  size     = 20
}

resource "yandex_compute_instance" "kittygram-vm" {
  name        = "kittygram-vm"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    disk_id = yandex_compute_disk.kittygram-boot-disk.id
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.kittygram-subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kittygram-security-group.id]
  }
  metadata = {
    ssh-keys  = "ubuntu:${tls_private_key.kittygram_ssh_key.public_key_openssh}"
    user-data = <<-EOF
      datasource:
        Ec2:
          strict_id: false
      ssh_pwauth: no
      users:
      - name: ubuntu
        sudo: "ALL=(ALL) NOPASSWD:ALL"
        shell: /bin/bash
        ssh_authorized_keys:
        - ${tls_private_key.kittygram_ssh_key.public_key_openssh}
      write_files:
        - path: "/usr/local/etc/docker-start.sh"
          permissions: "755"
          content: |
            #!/bin/bash

            # Docker
            echo "Installing Docker"
            sudo apt update -y && sudo apt install docker.io -y
            echo "Grant user access to Docker"
            sudo usermod -aG docker ubuntu
            newgrp docker

          defer: true
        - path: "/usr/local/etc/docker-main.sh"
          permissions: "755"
          content: |
            #!/bin/bash

            # Docker run container
            docker pull hello-world:latest
            docker run hello-world

          defer: true
      runcmd:
        - [su, ubuntu, -c, "/usr/local/etc/docker-start.sh"]
        - [su, ubuntu, -c, "/usr/local/etc/docker-main.sh"]
    EOF
  }
}
