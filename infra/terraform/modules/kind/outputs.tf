output "cluster_name" {
  description = "kind cluster name, also the kubeconfig context name"
  value       = kind_cluster.this.name
}

output "kubeconfig_path" {
  description = "Path to the standalone kubeconfig for this cluster"
  value       = local.kubeconfig_path
}

output "endpoint" {
  description = "Kubernetes API server endpoint"
  value       = kind_cluster.this.endpoint
}
