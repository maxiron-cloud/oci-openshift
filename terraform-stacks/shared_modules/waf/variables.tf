variable "compartment_ocid" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "enable_waf" {
  type    = bool
  default = false
}

variable "apps_lb_id" {
  type        = string
  description = "OCID of the apps load balancer to attach the WAF to."
}

variable "defined_tags" {
  type = map(string)
}
