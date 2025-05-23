resource "yandex_vpc_network" "kittygram-network" {
  name = "kittygram-network"
}

resource "yandex_vpc_address" "kittygram-static-ip" {
  name = "kittygram-static-ip"
  external_ipv4_address {
    zone_id = var.zone
  }
  lifecycle {
    prevent_destroy = true
  }
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
    nat_ip_address     = yandex_vpc_address.kittygram-static-ip.external_ipv4_address[0].address
    subnet_id          = yandex_vpc_subnet.kittygram-subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kittygram-security-group.id]
  }
  metadata = {
    ssh-keys  = "ubuntu:${var.vm_ssh_public_key}"
    user-data = <<-EOF
      #cloud-config
      datasource:
        Ec2:
          strict_id: false
      ssh_pwauth: no
      users:
      - name: ubuntu
        sudo: "ALL=(ALL) NOPASSWD:ALL"
        shell: /bin/bash
        ssh_authorized_keys:
        - ${var.vm_ssh_public_key}
      write_files:
        - path: "/usr/local/etc/docker-start.sh"
          permissions: "755"
          content: |
            #!/bin/bash

            set -e

            echo "Installing Docker"
            sudo apt update -y && sudo apt install -y docker.io curl

            echo "Grant user access to Docker"
            sudo usermod -aG docker ubuntu

            echo "Installing Docker Compose"
            curl -SL "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-$(uname -m)" -o /tmp/docker-compose
            sudo mv /tmp/docker-compose /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose

            echo "Docker Compose version:"
            docker-compose version

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
