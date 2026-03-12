Assessment – 1 (Infrastructure Provisioning using Terraform with CI/CD)



Create a complete cloud infrastructure (AWS or GCP) using Terraform and automate the provisioning process through a CI/CD pipeline (GitHub Actions).



Provision the following components using Terraform:



VPC with 2 public and 2 private subnets across Multi-AZ

Compute instances (EC2 / GKE / EKS nodes)

Private S3 or GCS bucket

NAT Gateway for private subnet internet access





The Terraform implementation must include:

Remote backend configuration for state file management

Use of input variables for environment-based deployment

Output values for infrastructure resources

Multi-AZ deployment for high availability



Configure a GitHub Actions pipeline to:

Run terraform init

Run terraform validate

Run terraform plan

Run terraform apply (manual approval)





Sol:



Step 1: The Terraform Code

1\. Create a folder named *terraform-aws-infra*. We'll create all four files here.

2\. The input: This defines the "knobs" you can turn, like choosing which region to deploy in.

 	      **variables.tf**

 	      variable "aws region" {

 	          default = "us-east-1"

 	      }



 	      variable "vpc\_cidr" {

 	          default = "10.0.0.0/16"

 	      }

3.The engine: The script builds your network (VPC), subnets, NAT Gateway and an S3 bucket.

 	      **main.tf**

 	      provider "aws" {

 		  region = var.aws\_region

 	      }



 	      # 1. Create the VPC

 	      resource "aws\_vpc" "main" {

  		  cidr\_block           = var.vpc\_cidr

  		  enable\_dns\_hostnames = true

  		  tags                 = { Name = "main-vpc" }

 	      }



 	      # 2. Create 2 Public Subnets (Multi-AZ)

 	      resource "aws\_subnet" "public" {

 		  count                   = 2

 		  vpc\_id                  = aws\_vpc.main.id

 		  cidr\_block              = "10.0.${count.index}.0/24"

 		  availability\_zone       = data.aws\_availability\_zones.available.names\[count.index]

 		  map\_public\_ip\_on\_launch = true

 		  tags                    = { Name = "public-subnet-${count.index}" }

 	      }



 	      # 3. Create 2 Private Subnets (Multi-AZ)

 	      resource "aws\_subnet" "private" {

 		  count             = 2

 		  vpc\_id            = aws\_vpc.main.id

 		  cidr\_block        = "10.0.${count.index + 2}.0/24"

 		  availability\_zone = data.aws\_availability\_zones.available.names\[count.index]

 		  tags              = { Name = "private-subnet-${count.index}" }

 	      }



 	      # 4. NAT Gateway (Allows private instances to reach the internet)

 	      resource "aws\_eip" "nat" { vpc = true }

 	      resource "aws\_nat\_gateway" "main" {

 		  allocation\_id = aws\_eip.nat.id

 		  subnet\_id     = aws\_subnet.public\[0].id # Place it in the first public subnet

 	      }



 	      # 5. Private S3 Bucket

 	      resource "aws\_s3\_bucket" "data\_store" {

 		  bucket = "my-unique-infra-bucket-${random\_id.id.hex}"

 	      }



 	      # Helper for AZs and IDs

 	      data "aws\_availability\_zones" "available" {}

 	      resource "random\_id" "id" { byte\_length = 4 }

4\. The results: This prints the IDs of your resources once built.

 		**outputs.tf**

 		output "vpc\_id" { value = aws\_vpc.main.id }

 		output "s3\_bucket\_name" { value = aws\_s3\_bucket.data\_store.id }

5\. The memory: Terraform needs to remember what it built. This "state" is stored in an S3 .bucket so multiple people can work on it.

 	       We need to create an S3 bucket beforehand (rach-terraform-bucket).

 	       **backend.tf**

 	       terraform {

 		  backend "s3" {

 		      bucket = "your-pre-created-state-bucket-name"

    		      key    = "state/terraform.tfstate"

    		      region = "us-east-1"

  		  }

 	       }





Step 2: The CI/CD Pipeline (GitHub Actions)

1. Create a folder in terraform-aws-infra. >.github/workflows/terraform.yml

   This tells GitHub: "Whenever I push code, run these terraform commands."

   **terraform.yml**

   name: "Terraform Infrastructure"



   on:

      push:

         branches: \[ "main" ]

      pull\_request:



   jobs:

      terraform:

         runs-on: ubuntu-latest

         env:

            AWS\_ACCESS\_KEY\_ID: ${{ secrets.AWS\_ACCESS\_KEY\_ID }}

            AWS\_SECRET\_ACCESS-KEY: ${{ secrets.AWS\_SECRET\_ACCESS-KEY }}



         steps:

            - name: Checkout Code

              uses: actions/checkout@v3



            - name: Setup Terraform

              uses: hashicorp/setup-terraform@v2

 

            - name: Terraform Init

              run: terraform init

 

            - name: Terraform Plan

              run: terraform plan

 

            - name: Terraform Apply

              if: github.ref == 'refs/heads/main' \&\& github.event\_name == 'push'

              run: terraform apply -auto-approve



Step 3: Connecting the dots

1. Add Secrets to GitHub: Go to GitHub Repo > Settings > Secrets and variables > Actions. Add Secret and Access Keys.

2\. The Push: You need to send your files from computer to GitHub. In the Command Prompt (Terminal), in terraform-aws-infra folder, do the following:

   2.1 Initialize Git: *git init*

   2.2 Add files: git add . (Dot: everything in the folder)

   2.3 Commit your work: git commit -m "Initial infrastructure deployment"

   2.4 Connect to GitHub: git remote add origin https://github.com/RachaelRathore/AWS-TASKS

 

