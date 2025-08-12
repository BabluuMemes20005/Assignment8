provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "flask_express" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  security_groups = [aws_security_group.flask_express_sg.name]

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "flask-express-single"
  }
}

resource "aws_security_group" "flask_express_sg" {
  name        = "flask-express-sg"
  description = "Allow Flask (5000), Express (3000), and SSH"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask app"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Express app"
    from_port   = 3000
    to_port     = 3000
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

output "public_ip" {
  value = aws_instance.flask_express.public_ip
}
