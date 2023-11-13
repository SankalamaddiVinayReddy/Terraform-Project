resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr
}


#aws subnet 
resource "aws_subnet" "subnet1" {
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.my_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  vpc_id = aws_vpc.my_vpc.id
  map_public_ip_on_launch = true
}

#internet gateway
resource "aws_internet_gateway" "ig_net" {
  vpc_id = aws_vpc.my_vpc.id
}


#aws route tables 
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table_association" "rta1" {
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.subnet1.id
}

resource "aws_route_table_association" "rta2" {
  route_table_id = aws_route_table.rt.id
  subnet_id = aws_subnet.subnet2.id
}

#creating security group with inbound and outbound rules
resource "aws_security_group" "sg1" {

  vpc_id = aws_vpc.my_vpc.id
  
ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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


#creating instances

resource "aws_instance" "server1" {
   ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  vpc_security_group_ids =[aws_security_group.sg1.id]
  subnet_id = aws_subnet.subnet1.id
  user_data = base64encode(file("samplefile.sh"))

}

resource "aws_instance" "server2" {
   ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  vpc_security_group_ids =[aws_security_group.sg1.id]
  subnet_id = aws_subnet.subnet2.id
  user_data = base64encode(file("samplefile2.sh"))

}

#application load balancer
resource "aws_lb" "lb" {
  name = "my-lb"
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]
  security_groups = [aws_security_group.sg1.id]
}

resource "aws_lb_target_group" "tg1" {
  name="My-target-1"
   vpc_id = aws_vpc.my_vpc.id
   protocol = "HTTP"
   port = 80
   
   health_check {
     path = "/"
     port = "traffic-port"
   }
}


resource "aws_lb_target_group_attachment" "lb_attach1" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id = aws_instance.server1.id
  port = 80
}
resource "aws_lb_target_group_attachment" "lb_attach2" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id = aws_instance.server2.id
  port = 80
}

resource "aws_lb_listener" "lb_s" {
  protocol = "HTTP"
  port = 80
  load_balancer_arn = aws_lb.lb.id
  default_action {
    target_group_arn = aws_lb_target_group.tg1.id
    type = "forward"
  }
}