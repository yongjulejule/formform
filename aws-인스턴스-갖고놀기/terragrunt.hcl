locals {
  # List of regions
  worker_regions     = ["us-west-1", "us-east-1", "ap-northeast-2"]
  controller_regions = ["ap-northeast-2"]
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
