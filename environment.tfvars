name                  = "project-varnish"
environment           = "prod"
availability_zones    = ["us-east-1a", "us-east-1b"]
private_subnets       = ["10.0.0.0/20", "10.0.32.0/20"]
public_subnets        = ["10.0.16.0/20", "10.0.48.0/20"]
tsl_certificate_arn   = "project certificate"
container_memory      = 1024
container_image       = "project-varnish-prod"
container_environment = "prod"












# remote state conf.
remote_state_key    = "PROD/platform.tfstate"
remote_state_bucket = "ecs-fargate-terraform-remote-state"

# service variables
ecs_service_name      = "springbootapp"
docker_container_port = 8080
desired_task_number   = "1"
spring_profile        = "default"
memory                = 1024
cpu                   = 256
task_definition_name  = "project-varnish"
terraform_state       = "project-terraform-backend-store-varnish"