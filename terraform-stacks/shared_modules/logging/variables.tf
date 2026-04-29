variable "compartment_ocid" {
  type        = string
  description = "OCI compartment OCID for the cluster."
}

variable "cluster_name" {
  type        = string
  description = "Cluster name used as a prefix for log group and log display names."
}

variable "apps_lb_id" {
  type        = string
  description = "OCID of the apps (ingress) Load Balancer."
}

variable "api_lb_id" {
  type        = string
  description = "OCID of the public API Load Balancer."
}

variable "waf_id" {
  type        = string
  default     = ""
  description = "OCID of the OCI WAF WebAppFirewall resource. Used in log source configuration."
}

variable "enable_waf" {
  type        = bool
  default     = false
  description = "Whether WAF is enabled. Controls creation of the WAF log stream (must be a static bool, not computed)."
}

# bastion_id and enable_bastion removed — OCI Bastion does not support SERVICE logging
# via oci_logging_log. Session activity is captured by OCI Audit automatically.

variable "log_retention_days" {
  type        = number
  default     = 90
  description = "Log retention period in days. ISO 27001 A.8.15 minimum is 90 days; recommended 365 days for production."
}

variable "enable_flow_logs" {
  type        = bool
  default     = true
  description = "Enable OCI VCN Flow Logs. Always true when logging is enabled (create-cluster passes true). Retained as a variable for module-level flexibility in standalone use."
}

variable "vcn_id" {
  type        = string
  default     = ""
  description = "OCID of the cluster VCN. Required when enable_flow_logs is true."
}

variable "defined_tags" {
  type        = map(string)
  default     = {}
  description = "OCI defined tags to apply to all logging resources."
}
