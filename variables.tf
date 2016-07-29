variable "docker_instance_type" {
  "default" = "m3.medium"
}

variable "docker_instance_root_block_device_volume_size" {
  "default" = "50"
}

variable "ssh_private_key_path" {
  "default" = "~/.ssh/id_rsa"
}

variable "ssh_public_key_path" {
  "default" = "~/.ssh/id_rsa.pub"
}
