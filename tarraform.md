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



