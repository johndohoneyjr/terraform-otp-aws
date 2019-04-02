terraform {
  required_version = ">= 0.11.1"
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_availability_zones" "available" {}

## Get the latest Centos AMI
##
data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
} 

##
## Default VPC is fine
##
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

##
## no SSH Headaches
##
resource "aws_security_group" "tf_public_sg" {
    name = "tf_public_sg"
    description = "PUBLIC SG"
    vpc_id      = "${aws_default_vpc.default.id}"
    #SSH

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #HTTP

    ingress {
         from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

data "template_file" "bootstrap" {
  template = "${file("${path.module}/userdata.tpl")}"
}

resource "aws_instance" "server" {
  ami                         = "${data.aws_ami.server_ami.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.ami_key_pair_name}"
  availability_zone           = "${data.aws_availability_zones.available.names[0]}"
  associate_public_ip_address = "true"

  provisioner "remote-exec" {
    connection {
      type    = "ssh"
      agent   = true
      host    = "${aws_instance.server.public_ip}"
      user    = "centos"
      timeout = "20s"
      private_key = "${file("/Users/johndohoneyjr/.ssh/dohoney-se-demos-west.pem")}"
    }

    inline = [
      "sudo apt-get update",
      "sudo apt install apt-transport-https ca-certificates curl software-properties-common -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable\"",
      "sudo apt update",
      "apt-cache policy docker-ce",
      "sudo apt install docker-ce -y",
      "sudo docker run -d -p 8080:8080 johndohoney/simplenodeapi"
    ]
  }
  tags {
    ## Dont fear the reaper
    Name = "dohoney-demo"
    owner = "jdohoney@hashicorp.com"
    ttl = "24"
  }
}

## Where do I ssh
##
output "public_ip_address" {
  value = "${aws_instance.server.public_ip}"
}

