variable "kubeconfig_path" {
  description = "Path to the kubeconfig for the cluster to install ArgoCD into"
  type        = string
}

variable "namespace" {
  description = "Namespace to install ArgoCD into"
  type        = string
  default     = "argocd"
}

variable "argocd_version" {
  description = "ArgoCD release tag (manifests are pulled from the matching argo-cd GitHub release)"
  type        = string
  default     = "v3.4.5"
}
