resource "aws_security_group" "redis_sg" {
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id         = "mctech-cart-cluster"
  engine             = "redis"
  node_type          = "cache.t2.micro"
  num_cache_nodes    = 1
  port               = 6379
  subnet_group_name  = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids = [data.aws_security_group.mctechdb_security_group.id]

  tags = {
    Name = "McTechCartRedisCluster"
  }
}

resource "kubernetes_secret" "mctechcart_secret" {
  metadata {
    name = "mctechcart-secret"
  }

  data = {
    REDIS_CONNECTION = "${aws_elasticache_cluster.redis.cluster_id}:${aws_elasticache_cluster.redis.port}"
  }

  depends_on = [aws_elasticache_cluster.redis]
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.configuration_endpoint
}

output "redis_connection" {
  value = "${aws_elasticache_cluster.redis.cluster_id}:${aws_elasticache_cluster.redis.port}"
}