data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet" "subnets" {
  count  = length(var.subnet_names)
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Name = element(var.subnet_names, count.index)
  }
}

resource "aws_security_group" "bastion-sg" {
  name        = var.bastion_sg_name
  description = "Bastion SG to enable external SSH access to the bastion host"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.bastion_sg_name
  }
}

data "aws_s3_bucket_object" "bastion_public_key_file" {
  bucket = var.public_key_bucket
  key    = var.public_key_path
}

resource "aws_key_pair" "bastion_key" {
  key_name   = var.bastion_key_name
  public_key = data.aws_s3_bucket_object.bastion_public_key_file.body
}

resource "aws_instance" "bastion-host" {
  count                       = length(data.aws_subnet.subnets.*.id)
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = aws_security_group.bastion-sg.*.id
  subnet_id                   = element(data.aws_subnet.subnets.*.id, count.index)
  key_name                    = aws_key_pair.bastion_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = var.bastion_host_name
  }
}
