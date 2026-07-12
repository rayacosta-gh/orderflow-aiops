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

module "argocd" {
  source = "../../modules/argocd"

  kubeconfig_path = module.cluster.kubeconfig_path

  depends_on = [module.cluster]
}
