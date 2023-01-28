provider "aws" { 
	access_key = "========================"
	secret_key = "========================"
	region = "ap-south-1"
}

resource "aws_vpc" "dev_vpc" {
	cidr_block = "10.0.0.0/24"

	tags = {
		Name = "Dev_vpc"
		ENV = "Dev_env"
	}
}

resource "aws_internet_gateway" "dev_IGW" { 
	vpc_id = aws_vpc.dev_vpc.id
	
	tags = { 
		Name = "dev_IGW"
		ENV = "Dev_env"
	}
}

resource "aws_subnet" "dev_subnet" { 
	vpc_id = aws_vpc.dev_vpc.id
	cidr_block = "10.0.0.0/24"
	availability_zone = "ap-south-1a"
	map_public_ip_on_launch = "true"

	tags = { 
		Name = "dev_subnet"
		ENV = "Dev_env"
	}
		
}

resource "aws_route_table" "dev_route_table" { 
	vpc_id = aws_vpc.dev_vpc.id
#	route { 
#		cidr_block = "0.0.0.0/0"
#		gateway_id = aws_internet_gateway.dev_IGW.id
#	}
	
	tags = {
		Name = "dev_route_table"
		ENV = "Dev_env"
	}
} 	

resource "aws_route_table_association" "dev_rt_assoc" { 
	route_table_id = aws_route_table.dev_route_table.id
	subnet_id = aws_subnet.dev_subnet.id
}	

resource "aws_route" "default_route" {
	route_table_id         = aws_route_table.dev_route_table.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id             = aws_internet_gateway.dev_IGW.id
}

resource "aws_security_group" "dev_sg" {
	name = "SG-23"
	vpc_id = aws_vpc.dev_vpc.id
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
		}
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
	tags = { 
		Name = "dev_SG"
	}
}

resource "aws_instance" "myEc2Server" {
	ami = "ami-06984ea821ac0a879"
	instance_type = "t2.micro"
	key_name = "KeyPairJan2022"
	subnet_id = aws_subnet.dev_subnet.id
	vpc_security_group_ids = [aws_security_group.dev_sg.id]
#	user_data = "${file("install_apache2.sh")}"
	tags = {
    		"Name" = "myec2server"
	}
connection { 
	type = "ssh"
	user = "ubuntu"
	private_key = "${file("KeyPairJan2022.pem")}"
	host = aws_instance.myEc2Server.public_ip
	agent = false
	timeout = "300s"
	}
provisioner "remote-exec" {
	inline = [
		"sudo apt-get update",
		"sudo apt-get install apache2 -y",
		"sudo systemctl start apache2",
		"sudo systemctl enable apache2"
	]
    
	}
}
output "myEc2Server_ip" { value = aws_instance.myEc2Server.public_ip }
