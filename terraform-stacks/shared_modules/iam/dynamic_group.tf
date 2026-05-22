resource "oci_identity_dynamic_group" "openshift_control_plane_nodes" {
  count = var.skip_cluster_iam_policies ? 0 : 1

  compartment_id = var.tenancy_ocid
  description    = "OpenShift control_plane nodes"

  matching_rule = "all {instance.compartment.id='${var.compartment_ocid}', tag.${var.op_openshift_tag_namespace}.${var.op_openshift_tag_instance_role}.value='control_plane'}"

  name         = "${var.cluster_name}_control_plane_nodes"
  defined_tags = var.defined_tags
}

resource "oci_identity_dynamic_group" "openshift_compute_nodes" {
  count = var.skip_cluster_iam_policies ? 0 : 1

  compartment_id = var.tenancy_ocid
  description    = "OpenShift compute nodes"
  matching_rule  = "all {instance.compartment.id='${var.compartment_ocid}', tag.${var.op_openshift_tag_namespace}.${var.op_openshift_tag_instance_role}.value='compute'}"
  name           = "${var.cluster_name}_compute_nodes"
  defined_tags   = var.defined_tags
}
