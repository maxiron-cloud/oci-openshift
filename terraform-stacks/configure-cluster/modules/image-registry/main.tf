terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

# Create PersistentVolumeClaim for image registry
resource "kubernetes_persistent_volume_claim_v1" "image_registry_storage" {
  metadata {
    name      = "image-registry-storage"
    namespace = "openshift-image-registry"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }

  wait_until_bound = false
}

# Configure OpenShift Image Registry to use the PVC
resource "kubectl_manifest" "image_registry_config" {
  yaml_body = <<-YAML
    apiVersion: imageregistry.operator.openshift.io/v1
    kind: Config
    metadata:
      name: cluster
    spec:
      managementState: Managed
      replicas: 1
      rolloutStrategy: Recreate
      storage:
        pvc:
          claim: ${kubernetes_persistent_volume_claim_v1.image_registry_storage.metadata[0].name}
      nodeSelector:
        node-role.kubernetes.io/master: ""
      tolerations:
        - key: node-role.kubernetes.io/master
          operator: Exists
          effect: NoSchedule
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
      defaultRoute: true
  YAML

  depends_on = [kubernetes_persistent_volume_claim_v1.image_registry_storage]
}

