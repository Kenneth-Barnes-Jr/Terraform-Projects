# My AWS Tenat (Kenneth's Workshop)
provider "aws" {
  region = "<your-region>"
}

resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow my IP for SSH and allow all for HTTP"
  vpc_id      = "<your-vpc-id>"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<your-ip-address>"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_sg"
  }
}

resource "aws_instance" "jenkins_server" {
  ami                         = "<ami-id>" # I used the Amazon Linux 2023 version 
  instance_type               = "t2.micro" 
  subnet_id                   = "<your-subnet-id>"
  key_name                    = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true # This allows for the Instance to have a public IP address

  user_data = <<-EOF
             #!/bin/bash
             sudo yum update && sudo yum upgrade -y
             sudo yum install java-17-amazon-corretto-devel -y #This a production-ready distribution of OpenJDK (Java Development Kit)
             sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo #Downloads the Jenkins repository configuration file and saves it in /etc/yum.repos.d/
             sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key #Imports the Jenkins GPG key to verify the authenticity of the Jenkins packages
             sudo yum install jenkins -y
             sudo systemctl start jenkins
             sudo systemctl enable jenkins
             sudo systemctl status jenkins #This command is not really needed just wanted to add it because it perform both start & enable
                EOF

  tags = {
    Name = "jenkins_web"
  }
}

resource "aws_s3_bucket" "j-repo" {
  bucket = "<your-bucket-name>"

  tags = {
    Name        = "jenkins_artifacts"
    Environment = "Dev"
  }
}
