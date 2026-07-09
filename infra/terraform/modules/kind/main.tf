terraform {
  required_version = ">= 1.5"

  required_providers {
    kind = {
      source = "tehcyx/kind"
    }
  }
}

locals {
  kubeconfig_path = var.kubeconfig_path != "" ? var.kubeconfig_path : "${path.root}/kubeconfig"
}

resource "kind_cluster" "this" {
  name            = var.cluster_name
  node_image      = var.node_image != "" ? var.node_image : null
  wait_for_ready  = var.wait_for_ready
  kubeconfig_path = local.kubeconfig_path

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }
  }
}

# kind has no built-in addon system (unlike minikube's `addons enable`), so
# metrics-server goes in the same way it would against a real cluster: apply
# the upstream manifest yourself. kind's kubelets serve self-signed certs
# metrics-server doesn't trust by default, hence the --kubelet-insecure-tls
# patch, which is a well-known requirement for any local (non-cloud) cluster.
resource "null_resource" "metrics_server" {
  depends_on = [kind_cluster.this]

  triggers = {
    cluster_endpoint = kind_cluster.this.endpoint
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local.kubeconfig_path
    }
    command = <<-EOT
      set -e
      kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
      kubectl patch deployment metrics-server -n kube-system --type=json \
        -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
    EOT
  }
}
