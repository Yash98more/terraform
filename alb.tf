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

In this post, we will see how to manage ALB in AWS via Terraform. We will also see how the requests are identified and treated differently based on the path. With AWS offering multiple services, it is also possible to integrate ALB with them. In the examples covered in this article, we integrate the ALB with EC2 instances, which are part of separate target groups.

What is AWS Application Load Balancer?
Prerequisites – the target architecture
Step 1: Configure EC2 instances
Step 2: Create an ALB Target Group
Step 3: Add the ALB Target Group attachment
Step 4: Create an ALB Listener
Step 5: Manage custom ALB Listener rules
Step 6: Test the path-based routing on ALB
How to integrate ALB with AWS Lambda
How to integrate ALB with AWS Web Application Firewall
What is AWS Application Load Balancer?
Load balancers are one of the crucial components of distributed architecture. They help assign incoming requests to multiple target servers to ensure efficiency and avoid delays and downtimes. There are two categories of load balancers – Application Load Balancer (ALB) and Network Load Balancer. 

AWS Application Load Balancers operate at layer 7 of the OSI model, making it better equipped to make routing decisions at the application level. ALBs can interpret an incoming request’s protocol, port, headers, method, and other attributes. We can leverage this capability to route the requests to appropriate processing destinations.

Prerequisites - the target architecture
terraform alb module
The diagram above represents the target architecture we want to achieve in this blog post. We will configure:

Application load balancer – which will route the incoming requests to the listener, where we configure the routing rules
Listener – that plays an important role in making routing decisions.
Listener rules – we will configure the listener rules to route the requests to various target groups.
Target group – each target group is a collection of EC2 instances that serve a specific request based on path value.
EC2 instances – each target group houses one EC2 instance. Each instance is configured with a Nginx web server, which responds uniquely.
To manage AWS Application Load Balancers with Terraform ALB resources, follow the steps below:

Configure the EC2 instances
Create an ALB Target Group
Add the ALB Target Group attachment
Create an ALB Listener
Manage custom ALB Listener rules
Test the path-based routing on ALB
The full source code for the examples discussed in this post is available here.

1. Configure EC2 instances
We want to serve requests based on what path they are targeted at. As the diagram above shows, incoming requests can be classified based on whether:

They are targeted toward the homepage
They are registration requests
They are related to images.
Each of the types described above needs to be served separately.

Let’s provision three EC2 instances serving the corresponding requests, as seen in the Terraform configuration below. 

We have used the user_data attribute to supply a script that installs and runs the nginx service. Further, each nginx is configured separately to serve separate paths:

Instance A – responds to root path
Instance B – responds to /images path
Instance C – responds to /register path
resource "aws_instance" "instance_a" { //Instance A
 ami           = var.ami
 instance_type = "t2.micro"

 subnet_id = var.subnet_a

 key_name = "tfserverkey"

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
 ami           = var.ami
 instance_type = "t2.micro"

 subnet_id = var.subnet_b

 key_name = "tfserverkey"

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
 ami           = var.ami
 instance_type = "t2.micro"

 subnet_id = var.subnet_c

 key_name = "tfserverkey"

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
Note: Since this post focuses on ALB, I have not covered the VPC networking part here. The example uses default VPCs and Subnets. See how to configure VPC networking using Terraform.

Testing the EC2 instances
Make sure you have three EC2 instances running in one AZ each, as seen in the screenshot below.

terraform aws alb
Access the homepage for Instance A, ./images/ path for Instance B and ./register/ path for Instance C. All of them should respond with an appropriate message displayed on the web page, as seen below.

terraform aws alb module
You should get the same result if your instance configuration is correct.

2. Create an ALB Target Group
Target groups – as the name suggests, are used to group compute resources that serve a single responsibility/purpose. 

In this example, resources that are part of each target group serve requests sent on a specific path. The Target Groups are described below:

Target Group A – is a group of instances that serves all the incoming requests targeted towards the home page, as well as all those requests that are not served by other target groups.
Target Group B – is a group of instances that serves all the incoming requests made on the /images path.
Target Group C – is a group of instances that serves all the incoming requests made on the /register path.
// Target groups
resource "aws_lb_target_group" "my_tg_a" { // Target Group A
 name     = "target-group-a"
 port     = 80
 protocol = "HTTP"
 vpc_id   = var.vpc_id
}

resource "aws_lb_target_group" "my_tg_b" { // Target Group B
 name     = "target-group-b"
 port     = 80
 protocol = "HTTP"
 vpc_id   = var.vpc_id
}

resource "aws_lb_target_group" "my_tg_c" { // Target Group C
 name     = "target-group-c"
 port     = 80
 protocol = "HTTP"
 vpc_id   = var.vpc_id
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