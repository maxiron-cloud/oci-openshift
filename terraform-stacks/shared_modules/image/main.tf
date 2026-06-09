terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

// Skip paravirtualized image only when every active tier (cp, compute, infra) is BM
resource "oci_core_image" "openshift_image_paravirtualized" {
  count          = var.create_openshift_instances && !var.use_placeholder_boot_image && (!var.is_control_plane_iscsi_type || !var.is_compute_iscsi_type || (var.infra_count > 0 && !var.is_infra_iscsi_type)) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.image_name}-paravirtualized"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = var.openshift_image_source_uri

    source_image_type = "QCOW2"
  }
  defined_tags = var.defined_tags

  # source_uri is a one-time import URL (PAR) that expires shortly after cluster creation.
  # Subsequent applies (cert-sync, monitoring updates, etc.) will not have the original URL,
  # causing Terraform to see a diff and try to replace the image. Ignore it — the image is
  # already imported and the source URI is irrelevant after initial creation.
  lifecycle {
    ignore_changes = [image_source_details]
  }
}

// Skip native image only when every active tier (cp, compute, infra) is VM
resource "oci_core_image" "openshift_image_native" {
  count          = var.create_openshift_instances && !var.use_placeholder_boot_image && (var.is_control_plane_iscsi_type || var.is_compute_iscsi_type || (var.infra_count > 0 && var.is_infra_iscsi_type)) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.image_name}-native"
  launch_mode    = "NATIVE"

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = var.openshift_image_source_uri

    source_image_type = "QCOW2"
  }
  defined_tags = var.defined_tags

  # Same rationale as openshift_image_paravirtualized above.
  lifecycle {
    ignore_changes = [image_source_details]
  }
}

locals {
  openshift_paravirtualized_image_id = var.use_placeholder_boot_image ? var.placeholder_boot_image_ocid : try(oci_core_image.openshift_image_paravirtualized[0].id, "")
  openshift_native_image_id          = var.use_placeholder_boot_image ? var.placeholder_boot_image_ocid : try(oci_core_image.openshift_image_native[0].id, "")
}

# Placeholder images are resolved with shape compatibility already (CLI lists images by shape).
# Registering compatibility on marketplace images can fail with OCI 500 InternalError.
resource "oci_core_shape_management" "imaging_control_plane_shape" {
  count          = var.create_openshift_instances && !var.use_placeholder_boot_image ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = var.is_control_plane_iscsi_type ? local.openshift_native_image_id : local.openshift_paravirtualized_image_id
  shape_name     = var.control_plane_shape
}

resource "oci_core_shape_management" "imaging_compute_shape" {
  count          = var.create_openshift_instances && !var.use_placeholder_boot_image ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = var.is_compute_iscsi_type ? local.openshift_native_image_id : local.openshift_paravirtualized_image_id
  shape_name     = var.compute_shape
}

# Register the infra shape's image compatibility only when it differs from the
# control-plane and compute shapes (those are already registered above) — avoids
# registering the same shape twice on the same image.
resource "oci_core_shape_management" "imaging_infra_shape" {
  count          = var.create_openshift_instances && !var.use_placeholder_boot_image && var.infra_count > 0 && var.infra_shape != var.compute_shape && var.infra_shape != var.control_plane_shape ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = var.is_infra_iscsi_type ? local.openshift_native_image_id : local.openshift_paravirtualized_image_id
  shape_name     = var.infra_shape
}

resource "oci_core_compute_image_capability_schema" "openshift_image_capability_schema_paravirtualized" {
  count                                               = var.create_openshift_instances && !var.use_placeholder_boot_image && (!var.is_control_plane_iscsi_type || !var.is_compute_iscsi_type) ? 1 : 0
  compartment_id                                      = var.compartment_ocid
  compute_global_image_capability_schema_version_name = local.global_image_capability_schemas[0].current_version_name
  image_id                                            = oci_core_image.openshift_image_paravirtualized[0].id
  schema_data                                         = merge(local.schema_vm)
  defined_tags                                        = var.defined_tags
}

resource "oci_core_compute_image_capability_schema" "openshift_image_capability_schema_native" {
  count                                               = var.create_openshift_instances && !var.use_placeholder_boot_image && (var.is_control_plane_iscsi_type || var.is_compute_iscsi_type) ? 1 : 0
  compartment_id                                      = var.compartment_ocid
  compute_global_image_capability_schema_version_name = local.global_image_capability_schemas[0].current_version_name
  image_id                                            = oci_core_image.openshift_image_native[0].id
  schema_data                                         = merge(local.schema_bare_metal)
  defined_tags                                        = var.defined_tags
}
