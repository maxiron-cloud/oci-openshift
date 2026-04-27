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
  description = "OCID of the OCI WAF WebAppFirewall resource. If empty, WAF logging is skipped."
}

variable "defined_tags" {
  type        = map(string)
  default     = {}
  description = "OCI defined tags to apply to all logging resources."
}
