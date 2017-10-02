provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "sams-example" {
    ami = "ami-3c715059"
    instance_type = "t2.micro"

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF

    tags {
        Name = "sams-terraform-example"
    }
}