output "cluster_name" {
  value = kind_cluster.lab5.name
}

output "context" {
  value = kind_cluster.lab5.context
}

output "endpoint" {
  value = kind_cluster.lab5.server
}

output "kubeconfig" {
  value     = kind_cluster.lab5.kubeconfig
  sensitive = true
}
