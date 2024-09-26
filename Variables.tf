
variable "password" {
  description = "The password for the database"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  default     = "mctechdb"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy the resources"
  default     = "us-east-1"
  type        = string
}

variable "project_name" {
  type        = string
  default     = "MechTechApi"
  description = "Especifica o nome do projeto"
}
