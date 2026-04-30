variable "compartment_ocid" {
  type        = string
  description = "OCI compartment OCID for the cluster."
}

variable "cluster_name" {
  type        = string
  description = "Cluster name used as a prefix for alarm and topic display names."
}

variable "tenant_name" {
  type        = string
  description = "Tenant code (e.g. 'analytica'). Included in every alarm body so downstream webhooks can identify the source tenant."
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
  description = "OCID of the OCI WAF WebAppFirewall resource. Used in alarm resource configuration."
}

variable "enable_waf" {
  type        = bool
  default     = false
  description = "Whether WAF is enabled. Controls creation of the WAF block-rate alarm (must be a static bool, not computed)."
}

variable "alert_webhook_url" {
  type        = string
  default     = ""
  sensitive   = true
  description = "HTTPS webhook URL (Teams/Slack/PagerDuty) for alarm notifications. Leave empty to skip webhook subscription."
}

variable "alert_email" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Email address for OCI ONS email subscription. Leave empty to skip."
}

variable "defined_tags" {
  type        = map(string)
  default     = {}
  description = "OCI defined tags to apply to all monitoring resources."
}
