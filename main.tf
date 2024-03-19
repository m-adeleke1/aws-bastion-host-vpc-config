# Configure AWS provider
provider "aws" {
  region = "us-east-1"  # Update with your desired region
}











# Define VPC
resource "aws_vpc" "adt_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "ADT_VPC"
  }
}










# Define Internet Gateway
resource "aws_internet_gateway" "adt_igw" {
  vpc_id = aws_vpc.adt_vpc.id

  tags = {
    Name = "ADT_IGW"
  }
}










# Define NAT Gateway
resource "aws_nat_gateway" "adt_nat" {
  allocation_id = aws_eip.adt_eip.id
  subnet_id     = aws_subnet.adt_public2.id

  tags = {
    Name = "ADT_NAT"
  }
}

# Define Elastic IP for NAT Gateway
resource "aws_eip" "adt_eip" {
  vpc = true
}










# Define Route Tables
resource "aws_route_table" "adt_public" {
  vpc_id = aws_vpc.adt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.adt_igw.id
  }

  tags = {
    Name = "ADT_Public"
  }
}

resource "aws_route_table" "adt_private" {
  vpc_id = aws_vpc.adt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.adt_nat.id
  }

  tags = {
    Name = "ADT_Private"
  }
}











# Define Subnets
resource "aws_subnet" "adt_public1" {
  vpc_id            = aws_vpc.adt_vpc.id
  cidr_block        = "192.168.0.0/26"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ADT_Public1"
  }
}

resource "aws_subnet" "adt_public2" {
  vpc_id            = aws_vpc.adt_vpc.id
  cidr_block        = "192.168.0.64/26"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "ADT_Public2"
  }
}

resource "aws_subnet" "adt_private1" {
  vpc_id            = aws_vpc.adt_vpc.id
  cidr_block        = "192.168.0.128/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "ADT_Private1"
  }
}

resource "aws_subnet" "adt_private2" {
  vpc_id            = aws_vpc.adt_vpc.id
  cidr_block        = "192.168.0.192/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "ADT_Private2"
  }
}










# Define EC2 Instances
# Define Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.adt_public1.id
  key_name      = "ADT_Test.pem"
  associate_public_ip_address = true

  tags = {
    Name = "Bastion"
  }

  # Specify the security group for Bastion
  security_groups = [aws_security_group.adt_public.name]
}

# Define Server EC2 Instance
resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.adt_private.id
  key_name      = "ADT_Test.pem"

  tags = {
    Name = "Server"
  }

  # Specify the security group for Server
  security_groups = [aws_security_group.adt_private.name]
}










# Define NACLs
# Define Public1 NACL
resource "aws_network_acl" "public1_nacl" {
  vpc_id = aws_vpc.adt_vpc.id
  subnet_ids = [aws_subnet.adt_public1.id]

  tags = {
    Name = "Public1"
  }
}

# Inbound rules for Public1 NACL
resource "aws_network_acl_rule" "public1_inbound_ssh" {
  network_acl_id = aws_network_acl.public1_nacl.id
  rule_number    = 110
  protocol       = "6"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.my_cidr
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "public1_inbound_custom_tcp" {
  network_acl_id = aws_network_acl.public1_nacl.id
  rule_number    = 120
  protocol       = "6"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound rules for Public1 NACL
resource "aws_network_acl_rule" "public1_outbound_custom_tcp" {
  network_acl_id = aws_network_acl.public1_nacl.id
  rule_number    = 110
  protocol       = "6"
  rule_action    = "allow"
  egress         = true
  cidr_block     = var.my_cidr
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public1_outbound_ssh" {
  network_acl_id = aws_network_acl.public1_nacl.id
  rule_number    = 120
  protocol       = "6"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "192.168.0.0/24"
  from_port      = 22
  to_port        = 22
}

# Define Public2 NACL
resource "aws_network_acl" "public2_nacl" {
  vpc_id = aws_vpc.adt_vpc.id
  subnet_ids = [aws_subnet.adt_public2.id]

  tags = {
    Name = "Public2"
  }
}

# Inbound rules for Public2 NACL
resource "aws_network_acl_rule" "public2_inbound_https" {
  network_acl_id = aws_network_acl.public2_nacl.id
  rule_number    = 110
  protocol       = "6"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "192.168.0.0/24"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public2_inbound_custom_tcp" {
  network_acl_id = aws_network_acl.public2_nacl.id
  rule_number    = 120
  protocol       = "6"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public2_inbound_icmp" {
  network_acl_id = aws_network_acl.public2_nacl.id
  rule_number    = 130
  protocol       = "1"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
}

# Outbound rules for Public2 NACL
resource "aws_network_acl_rule" "public2_outbound_https" {
  network_acl_id = aws_network_acl.public2_nacl.id
  rule_number    = 110
  protocol       = "6"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public2_outbound_custom_tcp" {
  network_acl_id = aws_network_acl.public2_nacl.id
  rule_number    = 120
  protocol       = "6"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "192.168.0.0/24"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public2_outbound_icmp" {
  network_acl_id = aws_network_acl.public2_nacl.id
  rule_number    = 130
  protocol       = "1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# Define ADT_Private34 NACL
resource "aws_network_acl" "adt_private34_nacl" {
  vpc_id = aws_vpc.adt_vpc.id
  subnet_ids = [aws_subnet.adt_private1.id, aws_subnet.adt_private2.id]

  tags = {
    Name = "ADT_Private34"
  }
}

# Inbound rules for ADT_Private34 NACL
resource "aws_network_acl_rule" "adt_private34_inbound_ssh" {
  network_acl_id = aws_network_acl.adt_private34_nacl.id
  rule_number    = 110
  protocol       = "6"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "192.168.0.0/24"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "adt_private34_inbound_icmp" {
  network_acl_id = aws_network_acl.adt_private34_nacl.id
  rule_number    = 120
  protocol       = "1"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "adt_private34_inbound_custom_tcp" {
  network_acl_id = aws_network_acl.adt_private34_nacl.id
  rule_number    = 130
  protocol       = "6"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound rules for ADT_Private34 NACL
resource "aws_network_acl_rule" "adt_private34_outbound_https" {
  network_acl_id = aws_network_acl.adt_private34_nacl.id
  rule_number    = 110
  protocol       = "6"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "adt_private34_outbound_icmp" {
  network_acl_id = aws_network_acl.adt_private34_nacl.id
  rule_number    = 120
  protocol       = "1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "adt_private34_outbound_custom_tcp" {
  network_acl_id = aws_network_acl.adt_private34_nacl.id
  rule_number    = 130
  protocol       = "6"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}










# Define Security Groups
# Define ADT_Public Security Group
resource "aws_security_group" "adt_public" {
  name        = "ADT_Public"
  description = "Allows SSH Access"
  vpc_id      = aws_vpc.adt_vpc.id

  # Inbound rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_cidr]
    description = "Remote Admin"
  }

  # Outbound rule for SSH
  egress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr]
  }
}

# Define ADT_Private Security Group
resource "aws_security_group" "adt_private" {
  name        = "ADT_Private"
  description = "Allows SSH Access"
  vpc_id      = aws_vpc.adt_vpc.id

  # Inbound rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"]
  }

  # Outbound rules for ICMP and HTTPS
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "icmp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

