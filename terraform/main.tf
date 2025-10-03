#############################################
# VPC
#############################################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

#############################################
# Internet Gateway + Route Table
#############################################
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

#############################################
# Subnets
#############################################
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public.id
}

#############################################
# Security Group
#############################################
resource "aws_security_group" "allow_web" {
  vpc_id = aws_vpc.main.id
  name   = "allow_web"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
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
    Name = "allow-web"
  }
}

#############################################
# Key Pair
#############################################
resource "aws_key_pair" "soly" {
  key_name   = "soly"
  public_key = file("~/.ssh/soly.pub")
}

#############################################
# EC2 Instances
#############################################
resource "aws_instance" "instance1" {
  ami                    = "ami-0669b163befffbdfc" # Ubuntu 22.04 eu-central-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet1.id
  key_name               = aws_key_pair.soly.key_name
  vpc_security_group_ids = [aws_security_group.allow_web.id]

  tags = {
    Name = "node-instance-1"
  }
}

resource "aws_instance" "instance2" {
  ami                    = "ami-0669b163befffbdfc"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet2.id
  key_name               = aws_key_pair.soly.key_name
  vpc_security_group_ids = [aws_security_group.allow_web.id]

  tags = {
    Name = "node-instance-2"
  }
}

#############################################
# Load Balancer
#############################################
resource "aws_lb" "app_lb" {
  name               = "nodejs-app-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  security_groups    = [aws_security_group.allow_web.id]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "nodejs-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "instance1" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance2" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.instance2.id
  port             = 80
}

#############################################
# Generate inventory.ini for Ansible
#############################################
resource "local_file" "ansible_inventory" {
  content = <<EOT
[docker_hosts]
${aws_instance.instance1.public_ip}
${aws_instance.instance2.public_ip}
EOT

  filename = "${path.module}/../inventory.ini"
}

#############################################
# Generate ansible.cfg
#############################################
resource "local_file" "ansible_cfg" {
  content = <<EOT
[defaults]
inventory = ../inventory.ini
remote_user = ubuntu
private_key_file = private_key.pem
host_key_checking = False
EOT

  filename = "${path.module}/../ansible/ansible.cfg"
}
