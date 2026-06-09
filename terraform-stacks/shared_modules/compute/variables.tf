variable "compartment_ocid" {
  type = string
}

variable "control_plane_shape" {
  type = string
}

variable "control_plane_boot_size" {
  type = number
}

variable "control_plane_boot_volume_vpus_per_gb" {
  type = number
}

variable "control_plane_memory" {
  type = number
}

variable "control_plane_ocpu" {
  type = number
}

variable "compute_shape" {
  type = string
}

variable "compute_boot_size" {
  type = number
}

variable "compute_boot_volume_vpus_per_gb" {
  type = number
}

variable "kms_key_id" {
  type        = string
  default     = ""
  description = "Optional OCI Vault customer-managed key OCID for boot volume encryption. Empty string uses Oracle-managed keys."
}

variable "compute_memory" {
  type = number
}

variable "compute_ocpu" {
  type = number
}

variable "infra_shape" {
  type    = string
  default = "VM.Standard.E5.Flex"
}

variable "infra_boot_size" {
  type    = number
  default = 300
}

variable "infra_boot_volume_vpus_per_gb" {
  type    = number
  default = 30
}

variable "infra_memory" {
  type    = number
  default = 32
}

variable "infra_ocpu" {
  type    = number
  default = 6
}

variable "is_infra_iscsi_type" {
  type    = bool
  default = false
}

variable "cluster_name" {
  type = string
}

variable "op_openshift_tag_boot_volume_type" {
  type = string
}

variable "op_openshift_tag_namespace" {
  type = string
}

variable "op_openshift_tag_instance_role" {
  type = string
}

variable "is_control_plane_iscsi_type" {
  type = bool
}

variable "is_compute_iscsi_type" {
  type = bool
}

variable "op_subnet_private_ocp" {
  type = string
}

variable "op_subnet_private_bare_metal" {
  type = string
}

variable "create_openshift_instances" {
  type = bool
}

variable "op_network_security_group_cluster_controlplane_nsg" {
  type = string
}

variable "op_network_security_group_cluster_compute_nsg" {
  type = string
}

variable "op_image_openshift_image_paravirtualized" {
  type = string
}

variable "op_image_openshift_image_native" {
  type = string
}

variable "op_lb_openshift_api_int_lb" {
  type = string
}

variable "op_lb_openshift_api_lb" {
  type = string
}

variable "op_lb_openshift_apps_lb" {
  type = string
}

variable "op_lb_bs_openshift_cluster_api_backend_set_external" {
  type = string
}

variable "op_lb_bs_openshift_cluster_ingress_http_backend_set" {
  type = string
}

variable "op_lb_bs_openshift_cluster_ingress_https_backend_set" {
  type = string
}

variable "op_lb_bs_openshift_cluster_api_backend_set_internal" {
  type = string
}

variable "op_lb_bs_openshift_cluster_infra-mcs_backend_set" {
  type = string
}

variable "op_lb_bs_openshift_cluster_infra-mcs_backend_set_2" {
  type = string
}

variable "op_lb_bs_openshift_cluster_infra-mcs_backend_set_api_2" {
  type = string
}

variable "op_lb_openshift_exposure_infra_lb" {
  type    = string
  default = ""
}

variable "op_lb_bs_openshift_exposure_infra_http_backend_set" {
  type    = string
  default = ""
}

variable "op_lb_bs_openshift_exposure_infra_https_backend_set" {
  type    = string
  default = ""
}

variable "installation_method" {
  type    = string
  default = "Assisted"
}

variable "rendezvous_ip" {
  default     = "10.0.16.20"
  type        = string
  description = "RendezvousIP from ABI"
}

variable "compute_node_map" {
  type = map(any)
}

variable "infra_node_map" {
  type    = map(any)
  default = {}
}

variable "cp_node_map" {
  type = map(any)
}

variable "distribute_cp_instances_across_fds" {
  description = "Whether control-plane instances should be distributed across Fault Domains in a round-robin sequence. If false, then the system will select one for you based on shape availability."
  type        = bool
}

variable "distribute_compute_instances_across_fds" {
  description = "Whether compute instances should be distributed across Fault Domains in a round-robin sequence. If false, then the system will select one for you based on shape availability."
  type        = bool
}

variable "distribute_infra_instances_across_fds" {
  description = "Whether infra instances should be distributed across Fault Domains in a round-robin sequence. If false, then the system will select one for you based on shape availability."
  type        = bool
  default     = true
}

variable "openshift_attribution_tag_namespace" {
  type    = string
  default = "openshift-tags"
}

variable "openshift_attribution_tag_key" {
  type    = string
  default = "openshift-resource"
}

variable "openshift_tag_openshift_resource_value" {
  type    = string
  default = "openshift-resource-infra"
}
