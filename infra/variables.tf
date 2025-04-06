variable "zone" {
  type        = string
  description = "The zone to deploy resources in"
  default     = "ru-central1-a"
}

variable "yandex_cloud_id" {
  type      = string
  sensitive = true
}

variable "yandex_folder_id" {
  type      = string
  sensitive = true
}

variable "yandex_srv_account_key_file" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_username" {
  type = string
}
