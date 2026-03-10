provider "aws" {
    region = var.aws_region
}

# 1. Create the VPC
resource "aws_vpc" "main" {
    cidr_block		 = var.vpc_cidr
    enable_dns_hostnames = true
    tags		 = { Name = "main-vpc" }

# 2. Create 2 Public Subnets (Multi-AZ)
resource "aws_subnet" "public" {
    count		    = 2
    vpc_id		    = aws_vpc.main.id
    cidr_block		    = "10.0.${count.index}.0/24"
    availability_zone	    = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true
    tags		    = { Name = "public-subnet-${count.index}" }
}

# 3. Create 2 Private Subnets (Multi-AZ)
resource "aws_subnet" "private" {
    count	      = 2
    vpc_id	      = aws_vpc.main.id
    cidr_block	      = "10.0.${count.index + 2}.0/24"
    availability_zone = data.aws_availability_zones.available.names[count.index]
    tags	      = { Name = "private-subnet-${count.index}" }
}

# 4. NAT Gateway (Allows private instances to reach the internet)
resource "aws_eip" "nat" { vpc = true }
resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id	  = aws_subnet.public[0].id  # Place it in the first public subnet
}

# 5. Private S3 Bucket
resource "aws_s3_bucket" "data_store" {
    bucket = "my-unique-infra-bucket-${random_id.id.hex}"
}

# Helper for AZs and IDs
data "aws_availability_zones" "available" {}
resource "random_id" "id" { byte_length = 4}

