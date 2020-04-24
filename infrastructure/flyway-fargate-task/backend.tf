terraform {
  required_version = ">= 0.12"

  backend "s3" {
    encrypt = true
    key     = "flyway-fargate-task.tfstate"
  }
}
