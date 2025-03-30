terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "state-bucket-a"
    region = "ru-central1-a"
    key    = "terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  zone                     = var.zone
  service_account_key_file = var.yandex_srv_account_key_file
  cloud_id                 = var.yandex_cloud_id
  folder_id                = var.yandex_folder_id
}
