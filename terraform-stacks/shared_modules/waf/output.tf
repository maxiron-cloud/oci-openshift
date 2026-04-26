output "waf_policy_id" {
  description = "OCID of the WAF policy (null when enable_waf=false)."
  value       = length(oci_waf_web_app_firewall_policy.apps_waf_policy) > 0 ? oci_waf_web_app_firewall_policy.apps_waf_policy[0].id : null
}

output "waf_id" {
  description = "OCID of the WAF attachment to the apps LB (null when enable_waf=false)."
  value       = length(oci_waf_web_app_firewall.apps_waf) > 0 ? oci_waf_web_app_firewall.apps_waf[0].id : null
}
