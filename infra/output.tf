output "external_ip" {
  description = "External IP address of the VM"
  value       = yandex_compute_instance.kittygram-vm.network_interface.0.nat_ip_address
}
