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

# Criação de security group para acesso ao banco de dados
data "aws_security_group" "mctechdb_security_group" {
  filter {
    name   = "group-name"
    values = ["SG-MechTechApi"]  # Substitua pelo nome do seu security group
  }
}

resource "aws_db_subnet_group" "my_subnet_group" {
  name       = "my-subnet-group"
  subnet_ids = data.aws_subnets.subnets.ids

  tags = {
    Name = "MyDBSubnetGroup"
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
  db_subnet_group_name    = aws_db_subnet_group.my_subnet_group.name
  vpc_security_group_ids  = [data.aws_security_group.mctechdb_security_group.id]
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  skip_final_snapshot     = true
}