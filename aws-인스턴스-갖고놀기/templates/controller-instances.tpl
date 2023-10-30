${join("\n\n", [for region in regions : <<-CONTENTS
 provider "aws" {
   alias  = "controller-${region}"
   region = "${region}"
 }
 module "vpc_controller_${region}" {
   source   = "./modules/controller/vpc"
   providers = {
     aws = aws.controller-${region}
   }
   region = "${region}"
 }
 module "ec2_instance_controller_${region}" {
   source    = "./modules/controller/ec2-instance"
   vpc_id    = module.vpc_controller_${region}.vpc_id
   subnet_id = module.vpc_controller_${region}.subnet_id
   providers = {
     aws = aws.controller-${region}
   }
   region = "${region}"
 }
 CONTENTS
 ])}
