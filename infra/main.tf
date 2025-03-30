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

resource "yandex_compute_disk" "kittygram-boot-disk" {
  name = "kittygram-boot-disk"
  type = "network-hdd"
  zone = var.zone
  size = 20
}

resource "tls_private_key" "kittygram_vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
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
    ssh-keys = "ubuntu:${tls_private_key.kittygram_vm_ssh_key.public_key_openssh}"
  }
}
