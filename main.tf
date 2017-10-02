provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "sams-example" {
    ami = "ami-3c715059"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.sams-security-group.id}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF


    tags {
        Name = "sams-terraform-example"
    }
}

resource "aws_security_group" "sams-security-group" {
    name = "sams-security-group"

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}