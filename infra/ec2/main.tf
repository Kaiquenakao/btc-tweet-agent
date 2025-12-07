resource "aws_security_group" "ec2_sg" {
  name        = "ec2-clone-sg"
  description = "Allow SSH"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = null
  associate_public_ip_address = true
  monitoring                  = false

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/agent-startup.sh", {
    region = var.region
  })

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "btc-tweet-agent"
  }
}
