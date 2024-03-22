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


// Target groups
resource "aws_lb_target_group" "my_tg_a" { // Target Group A
 name     = "target-group-a"
 port     = 80
 protocol = "HTTP"
 vpc_id   = "vpc-019705ca0646f00cd"
}

resource "aws_lb_target_group" "my_tg_b" { // Target Group B
 name     = "target-group-b"
 port     = 80
 protocol = "HTTP"
 vpc_id   = "vpc-019705ca0646f00cd"
}

resource "aws_lb_target_group" "my_tg_c" { // Target Group C
 name     = "target-group-c"
 port     = 80
 protocol = "HTTP"
 vpc_id   = "vpc-019705ca0646f00cd"
}



// Target group attachment
resource "aws_lb_target_group_attachment" "tg_attachment_a" {
 target_group_arn = aws_lb_target_group.my_tg_a.arn
 target_id        = aws_instance.instance_a.id
 port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment_b" {
 target_group_arn = aws_lb_target_group.my_tg_b.arn
 target_id        = aws_instance.instance_b.id
 port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment_c" {
 target_group_arn = aws_lb_target_group.my_tg_c.arn
 target_id        = aws_instance.instance_c.id
 port             = 80
}


resource "aws_lb" "my_alb" {
 name               = "my-alb"
 internal           = false
 load_balancer_type = "application"
 security_groups    = [sg-040ebdb207a22784f]
 subnets            = ["subnet-0b0026bf0a7b9cde0", "subnet-04ce27849ad34a574", "subnet-0cdc3f233d4530337"]

 tags = {
   Environment = "dev"
 }
}

resource "aws_lb_listener" "my_alb_listener" {
 load_balancer_arn = aws_lb.my_alb.arn
 port              = "80"
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.my_tg_a.arn
 }
}


resource "aws_lb_listener_rule" "rule_b" {
 listener_arn = aws_lb_listener.my_alb_listener.arn
 priority     = 60

 action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.my_tg_b.arn
 }

 condition {
   path_pattern {
     values = ["/images*"]
   }
 }
}

resource "aws_lb_listener_rule" "rule_c" {
 listener_arn = aws_lb_listener.my_alb_listener.arn
 priority     = 40

 action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.my_tg_c.arn
 }

 condition {
   path_pattern {
     values = ["/register*"]
   }
 }
}