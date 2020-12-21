provider "aws" {
  region = "eu-central-1"
}

resource "aws_security_group" "terraform" {
  name        = "terraform"
  description = "Used in the terraform"
  vpc_id      = "vpc-b765d3dd"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {

  connection {
    host = "${self.public_ip}"
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("~/.ssh/devops1.pem")}"
  }

  instance_type = "t2.micro"
  ami = "ami-0e1ce3e0deb8896d2"
  key_name = "my_keypair"
  vpc_security_group_ids = ["${aws_security_group.terraform.id}"]
  subnet_id = "subnet-2ac49667"

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
      "sudo chmod -R a+rw /var/www/html/",
    ]
  }

  provisioner "file" {
    source      = "index.html"
    destination = "/var/www/html/index.nginx-debian.html"
  }
}