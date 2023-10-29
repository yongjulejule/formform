locals {
  # List of regions
  regions = ["us-west-1", "us-east-1"]
}

# Loop over each region to create a provider config file
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents = templatefile("templates/regional-resources.tpl", { regions = local.regions })
  // contents  = <<-EOF
  //   ${join("\n\n", [for region in local.regions : <<-CONTENTS
  //   provider "aws" {
  //     alias  = "${region}"
  //     region = "${region}"
  //   }
  //   module "vpc_${region}" {
  //     source   = "./modules/vpc"
  //     providers = {
  //       aws = aws.${region}
  //     }
  //     region = "${region}"
  //   }
  //   module "ec2_instance_${region}" {
  //     source    = "./modules/ec2-instance"
  //     vpc_id    = module.vpc_${region}.vpc_id
  //     subnet_id = module.vpc_${region}.subnet_id
  //     providers = {
  //       aws = aws.${region}
  //     }
  //     region = "${region}"
  //   }
  //   CONTENTS
  //   ])}
  // EOF
}

terraform {
  source = "./"
  // source = "./modules//ec2-instance"
}
