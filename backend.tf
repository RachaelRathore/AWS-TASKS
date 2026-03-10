terraform {
    backend "s3" {
	bucket = "rach-terraform-bucket"
	key    = "state/terraform.tfstate"
	region = "us-east-1"
    }
}