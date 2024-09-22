# Centralizando algumas variáveis locais nesta seção
locals {
  name    = "mctech-sqlserverdb"
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
    Name = "mctech-sqlserverdb-vpc"
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
resource "aws_security_group" "mctechws_security_group" {
  name        = "mctechws-security-group"
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
    Name = "mctech-sqlserverdb-web-security-group"
  }
}

# Criação de security group para acesso ao banco de dados
resource "aws_security_group" "mctechdb_security_group" {
  name        = "mctechdb-security-group"
  description = "enable SQLServer access on port 1433"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description      = "SQLServer access"
    from_port        = 1433
    to_port          = 1433
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "mctech-sqlserverdb-database-security-group"
  }
}


# Cria grupo de subredes para a instância RDS
resource "aws_db_subnet_group" "mctechdb_subnet_group" {
  name         = "mctechdb-subnets"
  subnet_ids   = [aws_default_subnet.subnet_az1.id, aws_default_subnet.subnet_az2.id]
  description  = "Subnets for database instance"

  tags   = {
    Name = "mctech-sqlserverdb-database-subnets"
  }
}


# Cria a instância RDS em si
resource "aws_db_instance" "mctechdb_instance" {
  engine                  = "sqlserver-ex"
  engine_version          = "15.00"
  multi_az                = false
  identifier              = "mctech-sqlserverdb-rds-instance"
  username                = "mctech"
  password                = "changeit123" # Adicionar a secret
  instance_class          = "db.t3.micro"
  allocated_storage       = 50
  db_subnet_group_name    = aws_db_subnet_group.mctechdb_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.mctechdb_security_group.id]
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  skip_final_snapshot     = true
}