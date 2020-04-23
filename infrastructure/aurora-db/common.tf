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
