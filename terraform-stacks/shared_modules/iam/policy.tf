resource "time_sleep" "wait_after_control_plane_dynamic_group" {
  count = var.skip_cluster_iam_policies ? 0 : 1

  depends_on = [oci_identity_dynamic_group.openshift_control_plane_nodes[0]]

  create_duration = "30s"
}

resource "oci_identity_policy" "policy_openshift_control_plane_nodes" {
  count = var.skip_cluster_iam_policies ? 0 : 1

  compartment_id = var.compartment_ocid
  description    = "OpenShift control_plane nodes instance principal"
  name           = "${var.cluster_name}_control_plane_nodes"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage volume-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage file-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage instance-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage security-lists in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage load-balancers in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage objects in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage dns-zones in compartment id ${var.dns_compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage dns-records in compartment id ${var.dns_compartment_ocid}",
  ]
  defined_tags = var.defined_tags

  depends_on = [oci_identity_dynamic_group.openshift_control_plane_nodes[0]]
}

resource "oci_identity_policy" "policy_openshift_control_plane_nodes_tags" {
  count = var.skip_cluster_iam_policies ? 0 : 1

  compartment_id = var.tenancy_ocid
  description    = "Give OpenShift control_plane nodes access to use tag-namespaces for cluster resources"
  name           = "${var.cluster_name}_control_plane_nodes_tags"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to use tag-namespaces in tenancy",
  ]
  defined_tags = var.defined_tags

  depends_on = [time_sleep.wait_after_control_plane_dynamic_group]
}

resource "oci_identity_policy" "policy_openshift_control_plane_nodes_networking" {
  count = (
    !var.skip_cluster_iam_policies
    && var.compartment_ocid != var.networking_compartment_ocid
    && var.networking_compartment_ocid != null
  ) ? 1 : 0

  compartment_id = var.networking_compartment_ocid
  description    = "OpenShift control_plane nodes network access"
  name           = "${var.cluster_name}_control_plane_nodes_networking_access_policy"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage security-lists in compartment id ${var.networking_compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes[0].name} to manage virtual-network-family in compartment id ${var.networking_compartment_ocid}",
  ]
  defined_tags = var.defined_tags

  depends_on = [time_sleep.wait_after_control_plane_dynamic_group]
}
