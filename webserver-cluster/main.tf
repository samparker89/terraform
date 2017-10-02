variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = "8080"
}

provider "aws" {
  region = "us-east-2"
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "sams-autoscaling-group" {
  launch_configuration = "${aws_launch_configuration.sams-launch-configuration}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  min_size = 2
  max_size = 10

  tag{
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "sams-launch-configuration" {
  image_id = "ami-a7aa8ac2"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.sams-security-group.id}"]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF

  //Ensures terraform creates the new resource before destroying the old one. Must
  //also set this to true on any dependencies of this resource e.g. security groups
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "sams-security-group" {
  name = "sams-security-group"

  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}