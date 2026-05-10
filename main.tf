terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

#####################################################
# EC2 Instance - AZ1
resource "aws_instance" "web_application" {
  ami                         = "ami-091138d0f0d41ff90"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = "my-key-pair"
  user_data_replace_on_change = true

 user_data = <<-EOF
#!/bin/bash

apt update -y

DEBIAN_FRONTEND=noninteractive apt install -y \
apache2 \
php \
php-mysql \
libapache2-mod-php \
mysql-client \
curl \
unzip

systemctl start apache2
systemctl enable apache2

rm -rf /var/www/html/*

cd /tmp

curl -O https://wordpress.org/latest.tar.gz

tar -xzf latest.tar.gz

cp -r wordpress/* /var/www/html/

cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

sed -i 's/database_name_here/wordpress/' /var/www/html/wp-config.php
sed -i 's/username_here/admin/' /var/www/html/wp-config.php
sed -i 's/password_here/Admin12345!/' /var/www/html/wp-config.php
sed -i "s/localhost/${aws_db_instance.mysql_primary.address}/" /var/www/html/wp-config.php

chown -R www-data:www-data /var/www/html/

find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;

echo "ok" > /var/www/html/health.html
echo "ok" | tee /var/www/html/health.html
chown www-data:www-data /var/www/html/health.html
chmod 644 /var/www/html/health.html
systemctl restart apache2

EOF
  tags = {
    Name = "Web-Application"
  }
}

# EC2 Instance - AZ2
resource "aws_instance" "web_application2" {
  ami                         = "ami-091138d0f0d41ff90"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet_2.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = "my-key-pair"
  user_data_replace_on_change = true
  user_data = <<-EOF
#!/bin/bash

apt update -y

DEBIAN_FRONTEND=noninteractive apt install -y \
apache2 \
php \
php-mysql \
libapache2-mod-php \
mysql-client \
curl \
unzip

systemctl start apache2
systemctl enable apache2

rm -rf /var/www/html/*

cd /tmp

curl -O https://wordpress.org/latest.tar.gz

tar -xzf latest.tar.gz

cp -r wordpress/* /var/www/html/

cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

sed -i 's/database_name_here/wordpress/' /var/www/html/wp-config.php
sed -i 's/username_here/admin/' /var/www/html/wp-config.php
sed -i 's/password_here/Admin12345!/' /var/www/html/wp-config.php
sed -i "s/localhost/${aws_db_instance.mysql_primary.address}/" /var/www/html/wp-config.php

chown -R www-data:www-data /var/www/html/

find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;

echo "ok" > /var/www/html/health.html
echo "ok" | tee /var/www/html/health.html
chown www-data:www-data /var/www/html/health.html
chmod 644 /var/www/html/health.html
systemctl restart apache2

EOF

  tags = {
    Name = "Web-Application2"
  }
}

#####################################################
# Security Group - EC2 Web Application
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Security Group for EC2 Web Application"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description     = "HTTP from Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTPS from Load Balancer"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2-Security-Group"
  }
}

#####################################################
# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

# Public Subnet - AZ1
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public-Subnet-AZ1"
  }
}

# Private Subnet - AZ1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private-Subnet-AZ1"
  }
}

# Public Subnet - AZ2
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public-Subnet-AZ2"
  }
}

# Private Subnet - AZ2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private-Subnet-AZ2"
  }
}

#####################################################
# Elastic IP - AZ1
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"
  tags = {
    Name = "NAT-EIP-AZ1"
  }
}

# Elastic IP - AZ2
resource "aws_eip" "nat_eip_2" {
  domain = "vpc"
  tags = {
    Name = "NAT-EIP-AZ2"
  }
}

# NAT Gateway - AZ1
resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "NAT-Gateway-AZ1"
  }
}

# NAT Gateway - AZ2
resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id
  tags = {
    Name = "NAT-Gateway-AZ2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-internet-gateway"
  }
}

#####################################################
# Load Balancer
resource "aws_lb" "my_alb" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = {
    Name = "my-load-balancer"
  }
}

# Security Group - Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security Group for Load Balancer"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB-Security-Group"
  }
}

#####################################################
# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }

  tags = {
    Name = "Private-Route-Table-AZ1"
  }
}

resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name = "Private-Route-Table-AZ2"
  }
}

resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}

#####################################################
# Target Group
resource "aws_lb_target_group" "my_tg" {
    
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
health_check {
  path                = "/health.html"
  port                = "traffic-port"
  protocol            = "HTTP"
  matcher             = "200"
  healthy_threshold   = 2
  unhealthy_threshold = 2
  interval            = 30
}

  tags = {
    Name = "my-target-group"
  }
}
resource "aws_lb_target_group_attachment" "tg_attachment_1" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.web_application.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment_2" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.web_application2.id
  port             = 80
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}
#####################################################
# Security Group - Database
resource "aws_security_group" "db_sg" {
  name        = "db-security-group"
  description = "Security Group for RDS Database"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DB-Security-Group"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name = "my-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "my-db-subnet-group"
  }
}

# RDS MySQL
resource "aws_db_instance" "mysql_primary" {
  identifier             = "mysql-primary"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "wordpress"
  username               = "admin"
  password               = "Admin12345!"
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az               = true
  skip_final_snapshot    = true

  tags = {
    Name = "MySQL-Primary"
  }
}

#####################################################
# Bastion Host
resource "aws_instance" "bastion" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = "my-key-pair"
  associate_public_ip_address = true

  tags = {
    Name = "Bastion-Host"
  }
}

# Security Group للـ Bastion
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.my_vpc.id

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