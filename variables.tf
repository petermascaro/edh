# Default docker instance type
variable "docker_instance_type" {
  "default" = "m3.medium"
}

# Default docker root volume size
variable "docker_instance_root_block_device_volume_size" {
  "default" = "50"
}

# Default ssh private key path
variable "ssh_private_key_path" {
  "default" = "~/.ssh/id_rsa"
}

# Default ssh public key path
variable "ssh_public_key_path" {
  "default" = "~/.ssh/id_rsa.pub"
}
