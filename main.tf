provider "aws" {
  access_key = var.aws-access-key
  secret_key = var.aws-secret-key
  region     = var.aws-region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state
  lifecycle {
    prevent_destroy = true
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}



resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  # read_capacity  = 20
  # write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = var.project_tag
  }
}

terraform {
  backend "s3" {
    bucket         = "project-terraform-backend-store-varnish"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dynamodb-terraform-state-lock"
    encrypt        = true
  }
}



module "vpc" {
  source             = "./vpc"
  name               = var.name
  cidr               = var.cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  availability_zones = var.availability_zones
  environment        = var.environment
}



module "security_groups" {
  source         = "./security-groups"
  name           = var.name
  vpc_id         = module.vpc.id
  environment    = var.environment
  container_port = var.container_port
}

module "alb" {
  source              = "./alb"
  name                = var.name
  vpc_id              = module.vpc.id
  subnets             = module.vpc.public_subnets
  environment         = var.environment
  alb_security_groups = [module.security_groups.alb]
  alb_tls_cert_arn    = var.tsl_certificate_arn
  health_check_path   = var.health_check_path
}

module "ecr" {
  source      = "./ecr"
  name        = var.name
  environment = var.environment
}






module "ecs" {
  source                      = "./ecs"
  name                        = var.name
  environment                 = var.environment
  container_image             = "${module.ecr.aws_ecr_repository_url}/${var.container_image}:latest"
  mycontainer                 = "${module.ecr.aws_ecr_repository_url}:latest"
  region                      = var.aws-region
  subnets                     = module.vpc.private_subnets
  aws_alb_target_group_arn    = module.alb.aws_alb_target_group_arn
  ecs_service_security_groups = [module.security_groups.ecs_tasks]
  container_port              = var.container_port
  container_cpu               = var.container_cpu
  container_memory            = var.container_memory
  service_desired_count       = var.service_desired_count
  container_environment = [
    { name = "LOG_LEVEL",
    value = "DEBUG" },
    { name = "PORT",
    value = var.container_port }
  ]
}