output "pvc_name" {
  description = "Name of the PVC created for image registry"
  value       = kubernetes_persistent_volume_claim_v1.image_registry_storage.metadata[0].name
}

output "pvc_namespace" {
  description = "Namespace of the image registry PVC"
  value       = kubernetes_persistent_volume_claim_v1.image_registry_storage.metadata[0].namespace
}

