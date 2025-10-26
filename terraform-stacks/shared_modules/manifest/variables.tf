variable "compartment_ocid" {
  type = string
}

variable "oci_driver_version" {
  type = string

  validation {
    condition     = contains(["v1.30.0", "v1.32.0", "v1.32.0-UHP"], var.oci_driver_version)
    error_message = "The oci_driver_version must correspond to a folder in oci-openshift/custom_manifests/oci-ccm-csi-drivers."
  }
}

variable "op_vcn_openshift_vcn" {
  type = string
}


variable "op_apps_subnet" {
  type = string
}

variable "op_apps_security_list" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "zone_dns" {
  type = string
}

variable "rendezvous_ip" {
  type = string
}

variable "webserver_private_ip" {
  type = string
}

variable "vcn_cidr" {
  type = string
}

variable "compute_count" {
  type = number
}

variable "control_plane_count" {
  type = number
}

variable "public_ssh_key" {
  type = string
}

variable "redhat_pull_secret" {
  type = string
}

variable "http_proxy" {
  type    = string
  default = "fake http_proxy"
}

variable "https_proxy" {
  type    = string
  default = "fake https_proxy"
}

variable "no_proxy" {
  type    = string
  default = "fake no_proxy"
}

variable "is_disconnected_installation" {
  type    = bool
  default = false
}

variable "set_proxy" {
  type    = bool
  default = false
}

variable "use_oracle_cloud_agent" {
  type    = bool
  default = false
}

variable "oca_image_pull_link" {
  type    = string
  default = ""
}

variable "region_metadata" {
  type = string
}

# FSS (File Storage Service) StorageClass Configuration
variable "enable_fss_storage_class" {
  type        = bool
  description = "Enable FSS StorageClass in the cluster"
  default     = false
}

variable "fss_availability_domain" {
  type        = string
  description = "Availability Domain for FSS (e.g., UK-LONDON-1-AD-1)"
  default     = "UK-LONDON-1-AD-1"
}

variable "fss_compartment_ocid" {
  type        = string
  description = "Compartment OCID where FSS resources will be created (automatically set to cluster compartment)"
  default     = ""
}

variable "fss_mount_target_subnet_ocid" {
  type        = string
  description = "Subnet OCID for FSS mount target"
  default     = ""
}

variable "fss_export_options" {
  type        = string
  description = "JSON array of export options for FSS"
  default     = "[{\"source\": \"10.0.0.0/16\", \"access\": \"READ_WRITE\", \"identitySquash\": \"NONE\", \"requirePrivilegedSourcePort\": false}]"
}

variable "fss_encrypt_in_transit" {
  type        = string
  description = "Enable encryption in transit for FSS"
  default     = "false"
}