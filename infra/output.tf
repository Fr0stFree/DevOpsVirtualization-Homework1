output "external_ip" {
  description = "External IP address of the VM"
  value       = yandex_compute_instance.kittygram-vm.network_interface.0.nat_ip_address
}

output "ssh_private_key" {
  description = "SSH private key for the VM"
  value       = tls_private_key.kittygram_ssh_key.private_key_pem
  sensitive   = true
}
