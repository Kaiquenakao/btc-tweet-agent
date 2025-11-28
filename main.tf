module "ec2" {
  source = "./infra/ec2"

  ami_id    = "ami-0c0039bfde8cbfe27"
  subnet_id = "subnet-0a1c52410042a044e"
  vpc_id    = "vpc-0e9225ab2d16f8d9d"

  instance_type = "t2.micro"
}
