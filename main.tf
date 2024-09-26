# Configurações do AWS Provider
provider "aws" {
  region = var.aws_region
}

# Cria primeira subnet padrão
resource "aws_default_subnet" "subnet_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]
}

# Cria segunda subnet padrão
resource "aws_default_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.available_zones.names[1]
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
  engine                 = "sqlserver-ex"
  engine_version         = "15.00"
  multi_az               = false
  identifier             = "mctech-sqlserverdb-rds-instance"
  username               = "mctech"
  password               = var.password
  instance_class         = "db.t3.micro"
  allocated_storage      = 50
  db_subnet_group_name   = aws_db_subnet_group.my_subnet_group.name
  vpc_security_group_ids = [data.aws_security_group.mctechdb_security_group.id]
  availability_zone      = data.aws_availability_zones.available_zones.names[0]
  skip_final_snapshot    = true
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks-cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority[0].data)
}

resource "kubernetes_secret" "mctechapi_secret" {
  metadata {
    name = "mctechapi-secret"
  }

  data = {
    CONNECTION_STRING = "Server=${aws_db_instance.mctechdb_instance.address},${aws_db_instance.mctechdb_instance.port};Database=${var.db_name};User Id=mctech;Password=${var.password}"
  }
}
