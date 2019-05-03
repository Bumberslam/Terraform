provider "aws" {
  region     = "us-east-2"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "my_vpc2" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags {
    Name = "My VPC2"
  }
}

resource "aws_subnet" "2public_us_east_2a" {
  vpc_id     = "${aws_vpc.my_vpc2.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-2a"
  tags {
    Name = "2Public Subnet us-east-2a"
  }
}

resource "aws_subnet" "2public_us_east_2b" {
  vpc_id     = "${aws_vpc.my_vpc2.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2b"
  tags {
    Name = "2Public Subnet us-east-2b"
  }
}

resource "aws_internet_gateway" "my_vpc_igw2" {
  vpc_id = "${aws_vpc.my_vpc2.id}"
  tags {
    Name = "My VPC - Internet Gateway2"
  }
}

resource "aws_route_table" "my_vpc_public2" {
    vpc_id = "${aws_vpc.my_vpc2.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.my_vpc_igw2.id}"
    }
    tags {
        Name = "Public Subnets Route Table for My VPC2"
    }
}

resource "aws_route_table_association" "my_vpc_us_east_1a_public2" {
    subnet_id = "${aws_subnet.2public_us_east_2a.id}"
    route_table_id = "${aws_route_table.my_vpc_public2.id}"
}

resource "aws_route_table_association" "my_vpc_us_east_1b_public2" {
    subnet_id = "${aws_subnet.2public_us_east_2b.id}"
    route_table_id = "${aws_route_table.my_vpc_public2.id}"
}

resource "aws_security_group" "allow_http2" {
  name        = "allow_http2"
  description = "Allow HTTP inbound connections"
  vpc_id = "${aws_vpc.my_vpc2.id}"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "Allow HTTP Security Group2"
  }
}

resource "aws_launch_configuration" "web2" {
  image_id = "ami-0b500ef59d8335eee" # Red Hat Enterprise Linux 7.6 (With Tomcat)
  instance_type = "t2.micro"
  key_name = "CarlosFC"
  security_groups = ["${aws_security_group.allow_http2.id}"]
  associate_public_ip_address = true
}

resource "aws_security_group" "elb_http2" {
  name        = "elb_http2"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id = "${aws_vpc.my_vpc2.id}"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "Allow HTTP through ELB Security Group"
  }
}

resource "aws_elb" "web_elb2" {
  name = "web-elb2"
  security_groups = [
    "${aws_security_group.elb_http2.id}"
  ]
  subnets = [
    "${aws_subnet.2public_us_east_2a.id}",
    "${aws_subnet.2public_us_east_2b.id}"
  ]
  cross_zone_load_balancing   = true
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:8080/"
  }
  listener {
    lb_port = 8080
    lb_protocol = "http"
    instance_port = "8080"
    instance_protocol = "http"
  }
}

resource "aws_autoscaling_group" "web2" {
  name = "${aws_launch_configuration.web2.name}-asg"
  min_size             = 1
  desired_capacity     = 2
  max_size             = 4
  health_check_type    = "ELB"
  load_balancers = [
    "${aws_elb.web_elb2.id}"
  ]
  launch_configuration = "${aws_launch_configuration.web2.name}"
  availability_zones = ["us-east-2a", "us-east-2b"]
  vpc_zone_identifier  = [
    "${aws_subnet.2public_us_east_2a.*.id}",
    "${aws_subnet.2public_us_east_2b.*.id}"]
  }

resource "aws_autoscaling_policy" "web_policy_up2" {
  name = "web_policy_up2"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.web2.name}"
}

resource "aws_autoscaling_policy" "web_policy_down2" {
  name = "web_policy_down2"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.web2.name}"
}

output "ELB IP2" {
  value = "${aws_elb.web_elb2.dns_name}"
}
