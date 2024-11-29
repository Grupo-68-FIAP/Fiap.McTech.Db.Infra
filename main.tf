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

resource "aws_db_subnet_group" "sqlserver_subnet_group" {
  name       = "sqlserver-subnet-group"
  subnet_ids = data.aws_subnets.subnets.ids

  tags = {
    Name = "SqlServerSubnetGroup"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = aws_db_subnet_group.sqlserver_subnet_group.subnet_ids

  tags = {
    Name = "redis-subnet-group"
  }

  depends_on = [aws_db_subnet_group.sqlserver_subnet_group]
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
  db_subnet_group_name   = aws_db_subnet_group.sqlserver_subnet_group.name
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
    CONNECTION_STRING = "Server=${aws_db_instance.mctechdb_instance.address},${aws_db_instance.mctechdb_instance.port};Database=${var.mctech_db_name};User Id=mctech;Password=${var.password}"
  }

  depends_on = [aws_db_instance.mctechdb_instance]
}

resource "kubernetes_secret" "mctechpayments_secret" {
  metadata {
    name = "mctechpayments-secret"
  }

  data = {
    CONNECTION_STRING = "Server=${aws_db_instance.mctechdb_instance.address},${aws_db_instance.mctechdb_instance.port};Database=${var.payments_db_name};User Id=mctech;Password=${var.password};TrustServerCertificate=true"
  }

  depends_on = [aws_db_instance.mctechdb_instance]
}

resource "kubernetes_secret" "mctechorder_secret" {
  metadata {
    name = "mctech-order-secret"
  }

  data = {
    CONNECTION_STRING = "Server=${aws_db_instance.mctechdb_instance.address},${aws_db_instance.mctechdb_instance.port};Database=${var.orders_db_name};User Id=mctech;Password=${var.password};TrustServerCertificate=true"
  }

  depends_on = [aws_db_instance.mctechdb_instance]
}
