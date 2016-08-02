# AMI region hash for Amazon Linux 2016.03.3
variable "aws_amis" {
  "default" = {
    "ap-southeast-2" = "ami-dc361ebf"
  }
}

# Default user for ssh connection
variable "aws_instance_connection_user" {
  "default" = "ec2-user"
}

# Default region for aws provider
variable "aws_region" {
  "default" = "ap-southeast-2"
}

# Default source cidr for ssh connection
variable "ssh_source_cidr_block" {
  "default" = "0.0.0.0/0"
}

# Default source cidr for web (nginx/kibana) requests
variable "web_source_cidr_block" {
  "default" = "0.0.0.0/0"
}

# Default vpc cidr block
variable "aws_vpc_cidr_block" {
  "default" = "10.0.0.0/16"
}

# Default subnet cid block
variable "aws_subnet_cidr_block" {
  "default" = "10.0.1.0/24"
}

# Default key pair name
variable "aws_key_name" {
  "default" = "pm_keypair"
}

# Template provider
provider "aws" {
  region = "${var.aws_region}"
}

/* Create a key pair for ssh connectivity
   - pass an existing public key to create key pair */
resource "aws_key_pair" "pm_key_pair" {
  key_name   = "${var.aws_key_name}"
  public_key = "${file(var.ssh_public_key_path)}"
}

/* Create the vpc with defined cidr block
   - provide a matching name tag */
resource "aws_vpc" "pm_vpc" {
  cidr_block = "${var.aws_vpc_cidr_block}"

  tags {
    Name = "pm_vpc"
  }
}

/* Create an internet gateway for external traffic
   - provide a matching name tag */
resource "aws_internet_gateway" "pm_internet_gateway" {
  vpc_id = "${aws_vpc.pm_vpc.id}"

  tags {
    Name = "pm_internet_gateway"
  }
}

# Create a default route for the vpc
resource "aws_route" "pm_route" {
  route_table_id         = "${aws_vpc.pm_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.pm_internet_gateway.id}"
}

/* Create a vpc subnet with defined cidr block
   - configure public ip assignment
   - provide a matching name tag */
resource "aws_subnet" "pm_subnet" {
  vpc_id                  = "${aws_vpc.pm_vpc.id}"
  cidr_block              = "${var.aws_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    Name = "pm_subnet"
  }
}

/* Create a security group for the docker host
   - inbound 22 from ssh source cidr block
   - inbound 80 from web source cidr block
   - inbound 5601 from web source cidr block
   - output everything
   - provide a matching name tag */
resource "aws_security_group" "pm_security_group" {
  name        = "pm_web_security_group"
  description = "Allow SSH and HTTP"
  vpc_id      = "${aws_vpc.pm_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_source_cidr_block}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.web_source_cidr_block}"]
  }

  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["${var.web_source_cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "pm_security_group"
  }
}

/* Create docker host from amazon linux ami
   - configure user and key pair
   - configure instance size and type
   - configure vpc and subnet
   - configure userdata for security patching at boot
   - provide a matching name tag
   - copy over ansible source
   - install ansible dependencies
   - update pip and install ansible
   - run ansible playbook */
resource "aws_instance" "pm_docker" {
  connection {
    user = "${aws_instance_connection_user}"
  }

  instance_type = "${var.docker_instance_type}"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.docker_instance_root_block_device_volume_size}"
  }

  key_name               = "${aws_key_pair.pm_key_pair.id}"
  vpc_security_group_ids = ["${aws_security_group.pm_security_group.id}"]
  subnet_id              = "${aws_subnet.pm_subnet.id}"
  user_data              = "${file("userdata.sh")}"

  tags {
    Name = "pm_docker"
  }

  provisioner "file" {
    source      = "ansible"
    destination = "/tmp/"

    connection {
      user        = "${var.aws_instance_connection_user}"
      private_key = "${var.ssh_private_key_path}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -i yum -y install gcc libffi-devel openssl-devel",
      "sudo -i pip install --upgrade pip ansible",
      "ansible-playbook -b -i \"localhost,\" -c local /tmp/ansible/site.yml",
    ]

    connection {
      user        = "${var.aws_instance_connection_user}"
      private_key = "${var.ssh_private_key_path}"
    }
  }
}

# Output nginx endpoint
output "nginx_url" {
  value = "http://${aws_instance.pm_docker.public_ip}/"
}

# Output kibana endpoint
output "kibana_url" {
  value = "http://${aws_instance.pm_docker.public_ip}:5601/"
}
