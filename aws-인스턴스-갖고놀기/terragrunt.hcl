locals {
  # List of regions
  worker_regions     = ["ap-northeast-2"]
  controller_regions = ["ap-northeast-2"]
}

remote_state {
  backend = "s3"
  config = {
    bucket = "playground-bucket-42"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

generate "worker_provider" {
  path      = "worker_provider.tf"
  if_exists = "overwrite"
  contents  = templatefile("templates/worker-instances.tpl", { regions = local.worker_regions })
}

generate "controller_provider" {
  path      = "controller_provider.tf"
  if_exists = "overwrite"
  contents  = templatefile("templates/controller-instances.tpl", { regions = local.controller_regions })
}

terraform {
  source = "./"
}
