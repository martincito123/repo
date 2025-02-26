data "aws_ami" "main" {
  most_recent      = true

  filter {
    name   = "name"
    values = [var.instance_ami_name]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.main.id
  instance_type = "t3.micro"
  subnet_id     = "${element(aws_subnet.public.*.id, 0)}"
  associate_public_ip_address = true
  key_name = aws_key_pair.main.key_name
  security_groups = [aws_security_group.main.id]

  tags = var.tags
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file("/home/.ssh/id_rsa.pub")
}

resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  vpc_id      = "${aws_vpc.main.id}"
  description = "Allows all inbound traffic"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}