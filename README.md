Creating MySQL Credentials in AWS Secrets Manager (UI Only)
Purpose
To securely store MySQL database credentials in AWS Secrets Manager before creating the database using Terraform.
This approach avoids hardcoding credentials in Terraform files and follows AWS security best practices.

Prerequisites
AWS account with console access


No existing RDS database required



Step-by-Step Procedure

Step 1: Open AWS Secrets Manager
Log in to the AWS Management Console


In the search bar, type Secrets Manager


Click Secrets Manager


Click Store a new secret



Step 2: Select Secret Type
On the Secret type screen


Select:
  Other type of secret


Click Next


Note:
 The “Credentials for Amazon RDS database” option requires an existing database instance.
 Since the database will be created later using Terraform, Other type of secret is the correct choice.

Step 3: Enter Secret Value
Choose Plaintext (or Key/Value editor)


Enter the following JSON:


{
  "username": "admin",
  "password": "StrongPassword@123"
}

Encryption key:


Leave as Default (aws/secretsmanager)


Click Next



Step 4: Configure Secret Name and Description
Secret name:


prod/mysql/db-credentials

Description (optional):


MySQL database credentials for Terraform-managed RDS

Click Next



Step 5: Configure Automatic Rotation
Disable Automatic rotation


Click Next


Note:
 Rotation can be enabled later after the RDS database is created.

Step 6: Review and Store
Review all configuration details


Click Store


✅ The secret is now successfully created.

Step 7: Verify Secret Value
Click on the created secret:
 prod/mysql/db-credentials


Click Retrieve secret value


Confirm the stored JSON:


{
  "username": "admin",
  "password": "StrongPassword@123"
}




Step-by-step Explanation of Terraform Code for MySQL RDS with Secrets Manager

1️⃣ Provider Configuration (provider.tf)
provider "aws" {
  region = "ap-south-2"
}

What it does:
 This tells Terraform to use AWS as the cloud provider and operate in the ap-south-1 region (Mumbai).


Why it’s important:
 All AWS resources created by Terraform will be in this region. You can change this to any other AWS region as needed.



2️⃣ Fetching Secrets from AWS Secrets Manager (data.tf)
data "aws_secretsmanager_secret" "mysql_secret" {
  name = "prod/mysql/db-credentials"
}

data "aws_secretsmanager_secret_version" "mysql_secret_version" {
  secret_id = data.aws_secretsmanager_secret.mysql_secret.id
}

locals {
  mysql_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.mysql_secret_version.secret_string
  )
}

What it does:


The first data block locates the secret by name in AWS Secrets Manager.


The second data block fetches the actual secret value (latest version).


locals block decodes the JSON string (which contains username and password) into usable Terraform variables.


Why it’s important:
 Instead of hardcoding sensitive data like DB passwords, Terraform dynamically reads them securely from Secrets Manager.



3️⃣ Creating a VPC and Subnets (vpc.tf)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "mysql-vpc" }
}

resource "aws_subnet" "private_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-2a"
  tags = { Name = "private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-2b"
  tags = { Name = "private-subnet-2" }
}

What it does:


Creates a Virtual Private Cloud (VPC) with CIDR range 10.0.0.0/16.


Creates two private subnets in different availability zones (for high availability).


Why it’s important:
 The RDS instance will run inside this VPC and subnets, isolating it in your private network.



4️⃣ Security Group Allowing All Traffic (security.tf)
resource "aws_security_group" "mysql_sg" {
  name = "mysql-allow-all-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mysql-allow-all-sg" }
}

What it does:


Defines a Security Group that allows all inbound and outbound traffic from anywhere.


Why it’s important:
 For learning/testing purposes, it allows your RDS to be accessible.


Warning:
 This is NOT recommended for production because it exposes your DB to everyone.



5️⃣ DB Subnet Group and RDS Instance (rds.tf)
DB Subnet Group
resource "aws_db_subnet_group" "mysql" {
  name = "mysql-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags = { Name = "mysql-db-subnet-group" }
}

What it does:
 Creates a subnet group for RDS that includes the two private subnets.


Why it’s important:
 RDS requires this to know where to launch the database instances.



MySQL RDS Instance
resource "aws_db_instance" "mysql" {
  allocated_storage = 20
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  db_name = "appdb"

  username = local.mysql_credentials.username
  password = local.mysql_credentials.password

  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  db_subnet_group_name = aws_db_subnet_group.mysql.name

  publicly_accessible = false
  skip_final_snapshot = true

  tags = { Name = "mysql-rds-instance" }
}

What it does:


Creates a MySQL database instance with 20GB storage and specified instance type.


Uses the credentials from Secrets Manager (local.mysql_credentials) for username and password.


Runs inside the private subnets and uses the security group created earlier.


Not publicly accessible (private inside VPC).


Why it’s important:
 This is your actual MySQL database running securely inside your AWS environment.



6️⃣ Outputs (outputs.tf)
output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

What it does:
 Prints the RDS endpoint (DNS address) after Terraform applies the changes.


Why it’s important:
 You’ll need this endpoint to connect your application or clients to the database.



Summary — How It All Works Together
Secrets Manager stores your DB credentials securely (username and password).


Terraform fetches those secrets dynamically using the data blocks.


Terraform creates a VPC with private subnets and a security group allowing traffic (wide open in this case).


Terraform creates a DB subnet group using those private subnets.


Terraform provisions a MySQL RDS instance using the fetched credentials, inside the subnet group and security group.


Finally, it outputs the DB’s endpoint so you can connect to it.


