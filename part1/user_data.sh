#!/bin/bash
sudo yum update -y

# Install Python3 & pip
sudo amazon-linux-extras enable python3.8
sudo yum install python3.8 python3-pip -y

# Install Git
sudo yum install git -y

# Install Node.js & npm
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install PM2
sudo npm install -g pm2

# Clone your GitHub repo (replace URL)
cd /home/ec2-user
git clone https://github.com/<your-username>/<your-repo>.git app

# Backend setup
cd /home/ec2-user/app/backend
pip3 install -r requirements.txt
pm2 start "python3 app.py" --name backend --watch -- --host=0.0.0.0 --port=5000

# Frontend setup
cd /home/ec2-user/app/frontend
npm install
pm2 start "node server.js" --name frontend --watch

# Auto-start PM2 apps after reboot
pm2 startup systemd
pm2 save
