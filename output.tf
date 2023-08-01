# Output the kubeconfig for the EKS cluster
output "kubeconfig" {
  value = module.eks.kubeconfig
}