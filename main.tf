# Centralizando algumas variáveis locais nesta seção
locals {
  name    = "mctech-sqlserver"
  region  = "us-east-1"

  tags = {
    Name       = local.name
  }
}

# Configurações do AWS Provider
provider "aws" {
  region  = local.region
}


# Criação de uma VPC padrão
resource "aws_default_vpc" "default_vpc" {

  tags = {
    Name = "mctech-sqlserver-vpc"
  }
}


# Data Source que obtém todas as zonas disponíveis na região
data "aws_availability_zones" "available_zones" {}


# Cria primeira subnet padrão
resource "aws_default_subnet" "subnet_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]
}

# Cria segunda subnet padrão
resource "aws_default_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.available_zones.names[1]
}

# Criação de security group para acesso ao banco pela API
resource "aws_security_group" "webserver_security_group" {
  name        = "webserver-security-group"
  description = "Enable HTTP access on port 80"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description      = "HTTP access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp" 
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "mctech-sqlserver-web-security-group"
  }
}

# Criação de security group para acesso ao banco de dados
resource "aws_security_group" "database_security_group" {
  name        = "database-security-group"
  description = "enable SQLServer access on port 1433"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description      = "SQLServer access"
    from_port        = 1433
    to_port          = 1433
    protocol         = "tcp"
    security_groups  = [aws_security_group.webserver_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "mctech-sqlserver-database-security-group"
  }
}


# Cria grupo de subredes para a instância RDS
resource "aws_db_subnet_group" "database_subnet_group" {
  name         = "database-subnets"
  subnet_ids   = [aws_default_subnet.subnet_az1.id, aws_default_subnet.subnet_az2.id]
  description  = "Subnets for database instance"

  tags   = {
    Name = "mctech-sqlserver-database-subnets"
  }
}


# Cria a instância RDS em si
resource "aws_db_instance" "db_instance" {
  engine                  = "sqlserver-ex"
  engine_version          = "15.00"
  multi_az                = false
  identifier              = "mctech-sqlserver-rds-instance"
  username                = "mctech"
  password                = "changeit123" # Adicionar a secret
  instance_class          = "db.t3.micro"
  allocated_storage       = 200
  db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.database_security_group.id]
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  skip_final_snapshot     = true
}