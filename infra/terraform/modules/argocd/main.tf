terraform {
  required_version = ">= 1.5"
}

# No official Terraform provider manages an ArgoCD install itself (as
# opposed to ArgoCD's own resources, which the argocd/argocd provider
# handles) - same local-exec pattern as the kind cluster module, applying
# the upstream release manifest directly.
resource "null_resource" "argocd" {
  triggers = {
    namespace = var.namespace
    version   = var.argocd_version
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = var.kubeconfig_path
    }
    command = <<-EOT
      set -e
      kubectl create namespace ${var.namespace} --dry-run=client -o yaml | kubectl apply -f -
      # --server-side avoids the kubectl.kubernetes.io/last-applied-configuration
      # annotation entirely; ArgoCD's applicationsets.argoproj.io CRD is large
      # enough that client-side apply exceeds Kubernetes' 256KB annotation limit.
      kubectl apply --server-side --force-conflicts -n ${var.namespace} -f https://raw.githubusercontent.com/argoproj/argo-cd/${var.argocd_version}/manifests/install.yaml
      kubectl -n ${var.namespace} wait --for=condition=available --timeout=300s deployment/argocd-server
    EOT
  }
}
