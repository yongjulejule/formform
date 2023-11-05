${join("\n\n", [for region in regions : <<-CONTENTS
 provider "aws" {
   alias  = "${region}"
   region = "${region}"
 }

 module "vpc_${region}" {
   source   = "./modules/vpc"
   providers = {
     aws = aws.${region}
   }
   region = "${region}"
 }

 module "ec2_instance_${region}" {
   source    = "./modules/ec2-instance"
   vpc_id    = module.vpc_${region}.vpc_id
   subnet_id = module.vpc_${region}.subnet_id
   vpc_cidr  = module.vpc_${region}.vpc_cidr
   providers = {
     aws = aws.${region}
   }
   region = "${region}"
 }
 CONTENTS
 ])}
