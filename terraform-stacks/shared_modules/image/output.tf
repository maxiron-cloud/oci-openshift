output "op_image_openshift_image_paravirtualized" {
  value = var.use_placeholder_boot_image ? var.placeholder_boot_image_ocid : try(oci_core_image.openshift_image_paravirtualized[0].id, null)
}

output "op_image_openshift_image_native" {
  value = var.use_placeholder_boot_image ? var.placeholder_boot_image_ocid : try(oci_core_image.openshift_image_native[0].id, null)
}
