variable "server_port" {
    description = "The port the server will use for HTTP requests"
    default = "8080"
}

provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "sams-example" {
    ami = "ami-a7aa8ac2"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.sams-security-group.id}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF


    tags {
        Name = "sams-terraform-example"
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
}

output "sams-example_public_ip" {
    value = "${aws_instance.sams-example.public_ip}"
}