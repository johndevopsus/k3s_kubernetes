terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.59.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "ec2_tags" {
  type    = string
  default = "john"
}

variable "generated_key_name" {
  type    = string
  default = "john-tf-key"
}
variable "ec2_type" {
  type    = string
  default = "ubuntu"
}

# generation ssh key
resource "tls_private_key" "k3s-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.generated_key_name
  public_key = tls_private_key.k3s-key.public_key_openssh
  tags = {
    Name = "aws${var.generated_key_name}"
  }
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.generated_key.key_name}.pem"
  content  = tls_private_key.k3s-key.private_key_pem
  provisioner "local-exec" {
    command = "chmod 400 ./${var.generated_key_name}.pem"
  }
}

resource "aws_instance" "master" {
  ami                    = "ami-08d4ac5b634553e16"
  key_name               = var.generated_key_name
  vpc_security_group_ids = [aws_security_group.k3s_server.id]
  instance_type          = "t3a.medium"
  user_data = base64encode(templatefile("${path.module}/server-userdata.tmpl", {
    token = random_password.k3s_cluster_secret.result
  })) # token = shared secret used to join a server or agent to a cluster

  tags = {
    Name = "k3sServer${var.ec2_tags}"
  }

  depends_on = [aws_key_pair.generated_key]
}

resource "aws_instance" "worker" {
  ami                    = "ami-08d4ac5b634553e16"
  key_name               = var.generated_key_name
  vpc_security_group_ids = [aws_security_group.k3s_agent.id]
  instance_type          = "t3a.medium"
  user_data = base64encode(templatefile("${path.module}/agent-userdata.tmpl", {
    host  = aws_instance.master.private_ip,
    token = random_password.k3s_cluster_secret.result
  }))
  depends_on = [aws_instance.master]
  tags = {
    Name = "k3sWorker${var.ec2_tags}"
  }
}

output "ssh_master" {
  description = "URL of ssh to Master"
  value       = "ssh -i ${var.generated_key_name}.pem ${var.ec2_type}@${aws_instance.master.public_ip}"
}

output "ssh_worker" {
  description = "URL of ssh to Worker"
  value       = "ssh -i ${var.generated_key_name}.pem ${var.ec2_type}@${aws_instance.worker.public_ip}"
}

# provisioner "local-exec" {
#     command = "rm -f ./${var.generated_key_name}.pem"
#     when    = destroy
#   }