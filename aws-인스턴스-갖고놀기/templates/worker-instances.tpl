 ${join("\n\n", [for region in regions : <<-CONTENTS
 provider "aws" {
   alias  = "worker-${region}"
   region = "${region}"
 }
 module "vpc_worker_${region}" {
   source   = "./modules/worker/vpc"
   providers = {
     aws = aws.worker-${region}
   }
   region = "${region}"
 }
 module "ec2_instance_worker_${region}" {
   source    = "./modules/worker/ec2-instance"
   vpc_id    = module.vpc_worker_${region}.vpc_id
   subnet_id = module.vpc_worker_${region}.subnet_id
   providers = {
     aws = aws.worker-${region}
   }
   region = "${region}"
 }
 CONTENTS
 ])}
