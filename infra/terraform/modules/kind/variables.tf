variable "cluster_name" {
  description = "kind cluster name"
  type        = string
  default     = "orderflow"
}

variable "node_image" {
  description = "kind node image (e.g. \"kindest/node:v1.31.2\"). Empty string uses kind's own default for the installed kind version."
  type        = string
  default     = ""
}

variable "worker_count" {
  description = "Number of worker nodes in addition to the single control-plane node"
  type        = number
  default     = 0
}

variable "wait_for_ready" {
  description = "Block until the control plane is ready before Terraform considers the cluster created"
  type        = bool
  default     = true
}

variable "kubeconfig_path" {
  description = "Where to write the cluster's standalone kubeconfig. Empty string defaults to <root module dir>/kubeconfig, deliberately not the shared ~/.kube/config, so this doesn't clobber other cluster contexts."
  type        = string
  default     = ""
}
