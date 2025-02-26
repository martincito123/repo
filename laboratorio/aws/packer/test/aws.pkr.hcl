packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

variable "aws_access_key" {
  type    = string
  default = "${env("AWS_ACCESS_KEY_ID")}"
}

variable "aws_secret_key" {
  type    = string
  default = "${env("AWS_SECRET_ACCESS_KEY")}"
}

variable "region" {
  type    = string
  default = "${env("AWS_DEFAULT_REGION")}"
}

variable "ami_username" {
  type    = string
  default = "ubuntu"
}

data "amazon-ami" "ubuntu" {
  access_key = "${var.aws_access_key}"
  filters = {
    name                = "*ubuntu/images/hvm-ssd/ubuntu-focal-22.04-amd64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "${var.region}"
  secret_key  = "${var.aws_secret_key}"
}
# The following amazon-ebs source will use an Ubuntu v20.04 AMI
# as referenced from the data above to install Nginx
source "amazon-ebs" "nginx" {
  access_key       = "${var.aws_access_key}"
  ami_description  = "Ubuntu server with Nginx"
  ami_name         = "nginx-packer-${formatdate("MM-DD-YY_hh-mm-ss", timestamp())}"
  communicator     = "ssh"
  force_deregister = "true"
  instance_type    = "t3.micro"
  region           = "${var.region}"
  secret_key       = "${var.aws_secret_key}"
  source_ami       = "${data.amazon-ami.ubuntu.id}"
  ssh_username     = "${var.ami_username}"
}
# The following will setup Nginx using Ansible Provisioner
# inside the amazon-ebs source
# After this build, there should now be a new AMI (Amazon Machine Image)
build {
  sources = ["source.amazon-ebs.nginx"]

  provisioner "ansible" {
    extra_arguments = ["--scp-extra-args", "'-O'", "--ssh-extra-args", "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa"]
    playbook_file   = "nginx.yaml"
    user            = "${var.ami_username}"
  }
}