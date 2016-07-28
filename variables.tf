# amazon linux 2016.03.3
variable "aws_amis" {
  "default" = {
    "ap-southeast-2" = "ami-dc361ebf"
  }
}

variable "aws_instance_connection_user" {
  "default" = "ec2-user"
}

variable "aws_instance_type" {
  "default" = "m3.medium"
}

variable "aws_instance_root_block_device_volume_size" {
  "default" = "50"
}

variable "aws_region" {
  "default" = "ap-southeast-2"
}

variable "aws_key_name" {
  "default" = "pm_keypair"
}

variable "aws_public_key_path" {
  "default" = "~/.ssh/id_rsa.pub"
}

variable "aws_vpc_cidr_block" {
  "default" = "10.0.0.0/16"
}

variable "aws_subnet_cidr_block" {
  "default" = "10.0.1.0/24"
}

variable "private_key" {
  "default" = "~/.ssh/id_rsa"
}

variable "ssh_source_cidr_block" {
  "default" = "0.0.0.0/0"
}

variable "web_source_cidr_block" {
  "default" = "0.0.0.0/0"
}
