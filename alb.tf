terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.42.0"
    }
  }
}

 provider "aws" {
  region = "ap-northeast-1"
  shared_config_files      = ["/home/ubuntu/.aws/config"]
  shared_credentials_files = ["/home/ubuntu/.aws/credentials"]
  profile = "yash"
}


resource "aws_instance" "instance_a" { //Instance A
 ami           = "ami-0eba6c58b7918d3a1"
 instance_type = "t2.micro"

 subnet_id = "subnet-0b0026bf0a7b9cde0"

 key_name = "marsadiz"

 tags = {
   Name = "Instance A"
 }

 user_data = <<-EOF
             #!/bin/bash
             sudo apt-get update
             sudo apt-get install -y nginx
             sudo systemctl start nginx
             sudo systemctl enable nginx
             echo '<!doctype html>
             <html lang="en"><h1>Home page!</h1></br>
             <h3>(Instance A)</h3>
             </html>' | sudo tee /var/www/html/index.html
             EOF
}

resource "aws_instance" "instance_b" { //Instance B
 ami           = "ami-0eba6c58b7918d3a1"
 instance_type = "t2.micro"

 subnet_id = "subnet-04ce27849ad34a574"

 key_name = "marsadiz"

 tags = {
   Name = "Instance B"
 }

 user_data = <<-EOF
             #!/bin/bash
             sudo apt-get update
             sudo apt-get install -y nginx
             sudo systemctl start nginx
             sudo systemctl enable nginx
             echo '<!doctype html>
             <html lang="en"><h1>Images!</h1></br>
             <h3>(Instance B)</h3>
             </html>' | sudo tee /var/www/html/index.html
             echo 'server {
                       listen 80 default_server;
                       listen [::]:80 default_server;
                       root /var/www/html;
                       index index.html index.htm index.nginx-debian.html;
                       server_name _;
                       location /images/ {
                           alias /var/www/html/;
                           index index.html;
                       }
                       location / {
                           try_files $uri $uri/ =404;
                       }
                   }' | sudo tee /etc/nginx/sites-available/default
             sudo systemctl reload nginx
             EOF
}

resource "aws_instance" "instance_c" { //Instance C
 ami           = "ami-0eba6c58b7918d3a1"
 instance_type = "t2.micro"

 subnet_id = "subnet-0cdc3f233d4530337"

 key_name = "marsadiz"

 tags = {
   Name = "Instance C"
 }

 user_data = <<-EOF
             #!/bin/bash
             sudo apt-get update
             sudo apt-get install -y nginx
             sudo systemctl start nginx
             sudo systemctl enable nginx
             echo '<!doctype html>
             <html lang="en"><h1>Register!</h1></br>
             <h3>(Instance C)</h3>
             </html>' | sudo tee /var/www/html/index.html
             echo 'server {
                       listen 80 default_server;
                       listen [::]:80 default_server;
                       root /var/www/html;
                       index index.html index.htm index.nginx-debian.html;
                       server_name _;
                       location /register/ {
                           alias /var/www/html/;
                           index index.html;
                       }
                       location / {
                           try_files $uri $uri/ =404;
                       }
                   }' | sudo tee /etc/nginx/sites-available/default
             sudo systemctl reload nginx
             EOF
}
