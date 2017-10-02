variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = "8080"
}

variable "all_ip_cidr"{
  description = "IP cidr range to allow all ips addresses"
  default = "0.0.0.0/0"
}

provider "aws" {
  region = "us-east-2"
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "sams-autoscaling-group" {
  launch_configuration = "${aws_launch_configuration.sams-launch-configuration.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  load_balancers = ["${aws_elb.sams-elb.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag{
    key = "Name"
    value = "sams-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "sams-elb"{
  name = "sams-elb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.sams-elb-security-group.id}"]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }

  //Will send a http request to each of the EC2 instances and will stop routing
  //traffic if it does not receive a 200 response.
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 30
    timeout = 3
    target = "HTTP:${var.server_port}/"
  }
}

resource "aws_launch_configuration" "sams-launch-configuration" {
  image_id = "ami-a7aa8ac2"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.sams-security-group.id}"]

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
    cidr_blocks = ["${var.all_ip_cidr}"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "sams-elb-security-group" {
  name = "sams-elb-security-group"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.all_ip_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.all_ip_cidr}"]
  }
}

output "elb_dns_name" {
  value = "${aws_elb.sams-elb.dns_name}}"
}