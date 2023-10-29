locals {
  # List of regions
  regions = ["us-west-1", "us-east-1", "ap-northeast-2"]
}

# Loop over each region to create a provider config file
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents = templatefile("templates/regional-instances.tpl", { regions = local.regions })
}

terraform {
  source = "./"
  // source = "./modules//ec2-instance"
}
