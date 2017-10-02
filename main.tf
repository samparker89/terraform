provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "sams-example" {
    ami = "ami-3c715059"
    instance_type = "t2.micro"

    tags {
        Name = "sams-terraform-example"
    }
}