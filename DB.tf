resource "aws_subnet" "private_us_east_2a-db" {
  vpc_id     = "${aws_vpc.my_vpc.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-2a"
  tags {
    Name = "Private Subnet us-east-2a-db"
  }
  map_public_ip_on_launch = "false"
}

resource "aws_subnet" "private_us_east_2b-db" {
  vpc_id     = "${aws_vpc.my_vpc.id}"
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-2b"
  tags {
    Name = "Private Subnet us-east-2b-db"
  }
  map_public_ip_on_launch = "false"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  subnet_ids  = ["${aws_subnet.private_us_east_2a-db.id}",
                 "${aws_subnet.private_us_east_2b-db.id}"
  ]
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Allow DB"
  vpc_id = "${aws_vpc.my_vpc.id}"
  ingress {
    from_port   = 9043
    to_port     = 9043
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   tags {
    Name = "Allow DB through Security Group"
  }
}

resource "aws_db_instance" "mysql_instance" {
  	allocated_storage    = 10
        storage_type         = "gp2"
        engine               = "mysql"
        engine_version       = "5.7"
        instance_class       = "db.t2.micro"
        name                 = "mydatabase"
        username             = "mydatabase"
        password             = "mydatabase"
	db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.id}"
	vpc_security_group_ids = ["${aws_security_group.db_sg.id}"]
	skip_final_snapshot = "true"
 tags {
		Name = "TerraformDBInstance"
      }
}
