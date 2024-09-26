data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_vpc" "vpc" {
  cidr_block = "172.31.0.0/16"
}

data "aws_subnet" "subnet" {
  for_each = toset(data.aws_subnets.subnets.ids)
  id       = each.value
}

data "aws_security_group" "mctechdb_security_group" {
  filter {
    name   = "group-name"
    values = ["SG-MechTechApi"]
  }
}

# Data Source que obtém todas as zonas disponíveis na região
data "aws_availability_zones" "available_zones" {}

data "aws_eks_cluster" "eks-cluster" {
  name = var.project_name
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = data.aws_eks_cluster.eks-cluster.name
}