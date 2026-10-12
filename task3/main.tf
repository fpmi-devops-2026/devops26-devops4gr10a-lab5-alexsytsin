terraform {
  required_providers {
    kind = {
      source  = "justenwalker/kind"
      version = "0.17.0"
    }
  }
  required_version = ">= 1.2"
}

provider "kind" {}

# Кластер из трёх нод (аналог 3 виртуальных машин):
# control-plane + два worker'а. На control-plane проброшен
# порт 30080 - через него NodePort-сервис доступен с хоста.
resource "kind_cluster" "lab5" {
  name  = var.cluster_name
  image = "kindest/node:v1.34.0"

  config = <<-YAML
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
      - role: control-plane
        extraPortMappings:
          - containerPort: 30080
            hostPort: 30080
      - role: worker
      - role: worker
  YAML
}
