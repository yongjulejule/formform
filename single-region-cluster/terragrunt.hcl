locals {
  # List of regions
  regions = ["${get_env("SINGLE_CLUSTER_AWS_REGION")}"]
}

remote_state {
  backend = "s3"
  config = {
    bucket = "playground-bucket-42"
    key            = "${path_relative_to_include()}/${get_env("SINGLE_CLUSTER_AWS_REGION")}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = templatefile("templates/provider.tpl", { regions = local.regions })
}

terraform {
  source = "./"
}
