# Terraform

## Install

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Auto-completion

```bash
terraform -install-autocomplete
```

### IDE

syntax highlighting 없으면 타자를 못침

- VSCode: https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform

- vim: lvim 쓰면 알아서 해줌 (terraform-ls 란 language server 사용하는듯)


## gogo

- Getting Started 보면서 냅다 시작

### Docker

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "tutorial"

  ports {
    internal = 80
    external = 8000
  }
}

```

- `terraform init` 을 하면 `docker` provider 를 다운로드 받음
> .terraform/providers/registry.terraform.io/kreuzwerker/docker/3.0.2/darwin_arm64/terraform-provider-docker_v3.0.2 -> 이게 맞냐?
- `terraform apply` 하면 실행된.. 다고 했는데 안되는데? 
  - 도커 실행중 맞는데?
  - ![docker???](docker-ok.png)
  - 언젠가 내가 docker context 를 바꿔뒀나봄. unix socket 위치 잡아줘서 해결. (provider "docker" { host = "unix:///path/to/socket" } )
  - 암튼 실행해보니 잘됨
- `terraform destroy` 하면 삭제됨

### AWS EC2

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_instance" "app_server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
```

- terraform init
- terraform fmt - formatting
- terraform validate - syntax check
- terraform apply
  - 일단 만들어주긴 함. 
  - 지맘대로 설정을 잡긴 하는데 다 납득할만한듯? (왜 ubuntu?)
- 다중 리전으로 해보고 싶어서 냅다 region 을 array 로 넣었는데 실패했다.
```terraform
provider "aws" {
  region = "us-west-1"
  alias  = "usw1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "use1"
}

resource "aws_instance" "ec2_us_west_1" {
  provider = aws.usw1
  // other configuration...
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

resource "aws_instance" "ec2_us_east_1" {
  provider = aws.use1
  // other configuration...
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
```
이것도 실패했다. AMI (Amazon machine image) 라는 값이 있는데, 얘가 regional 하게 unique 란다. 얼탱.
