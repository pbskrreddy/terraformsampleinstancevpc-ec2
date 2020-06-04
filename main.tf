#This Terraform Code Deploys Basic VPC Infra.
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = {
        Name = "${var.vpc_name}"
	Owner = "Ram"
    }
    # depends_on = [aws_s3_bucket.ram-bucket]
}


resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
	tags = {
        Name = "${var.IGW_name}"
    }
}

resource "aws_subnet" "subnet1-publics" {
    count = 6 # it will create 4 subnets 0 to 3
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${element(var.cidrs, count.index)}"
    availability_zone = "${element(var.azs, count.index)}"

    tags = {
        Name = "Prod-Subnet-${count.index+1}"
    }
}

# resource "aws_subnet" "subnet2-public" {
#     vpc_id = "${aws_vpc.default.id}"
#     cidr_block = "${var.public_subnet2_cidr}"
#     availability_zone = "us-east-1b"

#     tags = {
#         Name = "${var.public_subnet2_name}"
#     }
# }

# resource "aws_subnet" "subnet3-public" {
#     vpc_id = "${aws_vpc.default.id}"
#     cidr_block = "${var.public_subnet3_cidr}"
#     availability_zone = "us-east-1c"

#     tags = {
#         Name = "${var.public_subnet3_name}"
#     }
	
# }

resource "aws_route_table" "terraform-public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags = {
        Name = "${var.Main_Routing_Table}"
    }
}

resource "aws_route_table_association" "terraform-public" {
    count = 6
    subnet_id       = "${element (aws_subnet.subnet1-publics.*.id, count.index)}"
    #subnet_id      = "${aws_subnet.subnet1-publics.id}" ##splat syntax
    route_table_id  = "${aws_route_table.terraform-public.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    }
}

# resource "aws_s3_bucket" "ram-bucket" {
#     bucket  = "devops-testing-depends"

#     tags = {
#         Name        = "my-bucket"
#         environment = "Dev"
#     }
# }

# data "aws_ami" "my_ami" {
#      most_recent      = true
#      #name_regex       = "^mavrick"
#      owners           = ["721834156908"]
# }


resource "aws_instance" "web-1" {
    count =3
    ami = "${lookup(var.amis, var.aws_region)}"
    #ami = "ami-0d857ff0f5fc4e03b"
    availability_zone =  "${element(var.azs, count.index)}"
    instance_type = "t2.micro"
    key_name = "LaptopKey"
    subnet_id = "${element(aws_subnet.subnet1-publics.*.id, count.index)}"
    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
    associate_public_ip_address = true	
    tags = {
        Name = "Server-${count.index}"
        Env = "Prod"
        Owner = "RamBhaskar"
	
    }
}

# #output "ami_id" {
#  value = "${data.aws_ami.my_ami.id}"
# }
# !/bin/bash
# echo "Listing the files in the repo."
# ls -al
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Packer Now...!!"
# packer build -var=aws_access_key=AAAAAAAAAAAAAAAAAA -var=aws_secret_key=BBBBBBBBBBBBB packer.json
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Terraform Now...!!"
# terraform init
# terraform apply --var-file terraform.tfvars -var="aws_access_key=AAAAAAAAAAAAAAAAAA" -var="aws_secret_key=BBBBBBBBBBBBB" --auto-approve

