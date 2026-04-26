terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

resource "oci_waf_web_app_firewall_policy" "apps_waf_policy" {
  count          = var.enable_waf ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-apps-waf-policy"

  actions {
    name = "blockAction"
    type = "RETURN_HTTP_RESPONSE"
    body {
      type = "STATIC_TEXT"
      text = "Request blocked by WAF."
    }
    code = 403
  }

  actions {
    name = "allowAction"
    type = "ALLOW"
  }

  request_protection {
    rules {
      name                       = "owasp-protection"
      type                       = "PROTECTION"
      action_name                = "blockAction"
      is_body_inspection_enabled = true
      protection_capabilities {
        key     = "9300000"
        version = 2
      }
    }
  }

  request_rate_limiting {
    rules {
      name        = "rate-limit-global"
      type        = "REQUEST_RATE_LIMITING"
      action_name = "blockAction"
      configurations {
        period_in_seconds          = 60
        requests_limit             = 500
        action_duration_in_seconds = 120
      }
    }
  }

  defined_tags = var.defined_tags
}

resource "oci_waf_web_app_firewall" "apps_waf" {
  count                      = var.enable_waf ? 1 : 0
  compartment_id             = var.compartment_ocid
  backend_type               = "LOAD_BALANCER"
  load_balancer_id           = var.apps_lb_id
  web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.apps_waf_policy[0].id
  display_name               = "${var.cluster_name}-apps-waf"
  defined_tags               = var.defined_tags
}
