terraform {
  required_version = ">= 1.5"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.11"
    }
  }
}

provider "kind" {}

module "cluster" {
  source = "../../modules/kind"

  cluster_name = "orderflow"
  worker_count = 0
}
