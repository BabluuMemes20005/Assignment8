provider "aws" {
  region = "ap-south-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "part2-vpc"
  }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "part2-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "part2-igw"
  }
}

# Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "part2-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

# Backend Security Group
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Allow backend + SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Flask API"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
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

# Frontend Security Group
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Allow frontend + SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP for frontend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
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

# Backend EC2 Instance
resource "aws_instance" "backend" {
  ami                         = "ami-0dee22c13ea7a9a67"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  key_name                    = "MyWeb"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3-pip
              pip3 install flask
              cat << 'PY' > /home/ec2-user/app.py
              from flask import Flask, request, jsonify
              app = Flask(__name__)
              @app.route('/submit', methods=['POST'])
              def submit():
                  data = request.json
                  name = data.get('name')
                  age = data.get('age')
                  return jsonify({'message': f'Received data for {name}, age {age}.'})
              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=5000)
              PY
              nohup python3 /home/ec2-user/app.py > /home/ec2-user/backend.log 2>&1 &
              EOF

  tags = {
    Name = "backend-ec2"
  }
}

# Frontend EC2 Instance
resource "aws_instance" "frontend" {
  ami                         = "ami-0dee22c13ea7a9a67"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
  key_name                    = "MyWeb"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
              yum install -y nodejs
              mkdir /frontend && cd /frontend
              cat << 'JS' > server.js
              const express = require('express');
              const bodyParser = require('body-parser');
              const axios = require('axios');
              const app = express();
              app.use(bodyParser.json());
              const BACKEND_URL = 'http://${aws_instance.backend.public_ip}:5000';
              app.get('/', (req, res) => {
                res.send('<form method="POST" action="/submit"><input name="name" placeholder="Enter your name" /><input name="age" placeholder="Enter your age" /><button type="submit">Submit</button></form>');
              });
              app.post('/submit', async (req, res) => {
                try {
                  const response = await axios.post(BACKEND_URL + '/submit', req.body);
                  res.send(response.data);
                } catch (err) {
                  res.status(500).send('Error connecting to backend.');
                }
              });
              app.listen(3000, '0.0.0.0', () => console.log('Frontend running on port 3000'));
              JS
              npm init -y
              npm install express body-parser axios
              nohup node server.js > /frontend/frontend.log 2>&1 &
              EOF

  tags = {
    Name = "frontend-ec2"
  }
}

output "backend_public_ip" {
  description = "Public IP of the backend EC2 instance"
  value       = aws_instance.backend.public_ip
}

output "frontend_public_ip" {
  description = "Public IP of the frontend EC2 instance"
  value       = aws_instance.frontend.public_ip
}
