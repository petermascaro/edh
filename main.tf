provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_key_pair" "pm_key_pair" {
  key_name   = "${var.aws_key_name}"
  public_key = "${file(var.aws_public_key_path)}"
}

resource "aws_vpc" "pm_vpc" {
  cidr_block = "${var.aws_vpc_cidr_block}"

  tags {
    Name = "pm_vpc"
  }
}

resource "aws_internet_gateway" "pm_internet_gateway" {
  vpc_id = "${aws_vpc.pm_vpc.id}"

  tags {
    Name = "pm_internet_gateway"
  }
}

resource "aws_route" "pm_route" {
  route_table_id         = "${aws_vpc.pm_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.pm_internet_gateway.id}"
}

resource "aws_subnet" "pm_subnet" {
  vpc_id                  = "${aws_vpc.pm_vpc.id}"
  cidr_block              = "${var.aws_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    Name = "pm_subnet"
  }
}

resource "aws_security_group" "pm_web_security_group" {
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "pm_ec2_security_group"
  }
}

resource "aws_instance" "pm_docker" {
  connection {
    user = "${aws_instance_connection_user}"
  }

  instance_type = "${var.aws_instance_type}"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${aws_instance_root_block_device_volume_size}"
  }

  key_name               = "${aws_key_pair.pm_key_pair.id}"
  vpc_security_group_ids = ["${aws_security_group.pm_web_security_group.id}"]
  subnet_id              = "${aws_subnet.pm_subnet.id}"
  user_data              = "${file("userdata.sh")}"

  tags {
    Name = "pm_docker"
  }

}

output "docker_host" {
  value = "${aws_instance.pm_docker.public_ip}"
}
