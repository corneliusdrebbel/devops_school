terraform {
  required_providers {
    aws = {
      version = "3.22.0"
    }
  }
}

provider "aws" {
  region = var.deploy_region
  access_key = var.my_access_key
  secret_key = var.my_secret_key
}

resource "aws_security_group" "tomcat_ssh" {
  name        = "allow_tomcat_ssh"
  description = "Allow traffic for Tomcat"
  vpc_id      = var.my_vpc_id

  ingress {
    description = "tcp in 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tomcat_ssh"
  }
}



resource "aws_instance" "build_instance" {
  tags = {
    Name = "build"
  }
  key_name = var.my_key_pair
  ami = var.image_id
  instance_type = var.inst_type
  vpc_security_group_ids = [aws_security_group.tomcat_ssh.id]
  user_data = <<EOF
#!/bin/bash
sudo apt update && sudo apt install -y openjdk-8-jdk maven git awscli
mkdir /data && cd /data && git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git
cd /data/boxfuse-sample-java-war-hello && mvn package
export AWS_ACCESS_KEY_ID=${var.my_access_key}
export AWS_SECRET_ACCESS_KEY=${var.my_secret_key}
export AWS_DEFAULT_REGION=${var.deploy_region}
aws s3 cp /data/boxfuse-sample-java-war-hello/target/hello-1.0.war ${var.my_bucket}
EOF
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [aws_instance.build_instance]
  create_duration = "60s"
}

resource "aws_instance" "prod_instance" {
  tags = {
    Name = "prod"
  }
  key_name = var.my_key_pair
  ami = var.image_id
  instance_type = var.inst_type
  vpc_security_group_ids = [aws_security_group.tomcat_ssh.id]
  depends_on = [time_sleep.wait_60_seconds]
  user_data = <<EOF
#!/bin/bash
sudo apt update && sudo apt install -y openjdk-8-jdk tomcat8 awscli
export AWS_ACCESS_KEY_ID=${var.my_access_key}
export AWS_SECRET_ACCESS_KEY=${var.my_secret_key}
export AWS_DEFAULT_REGION=${var.deploy_region}
aws s3 cp ${var.my_bucket}/hello-1.0.war /var/lib/tomcat8/webapps/hello-1.0.war
sudo systemctl restart tomcat8
EOF  
}