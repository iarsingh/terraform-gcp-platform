locals {
  # OWASP CRS preconfigured WAF rule sets to evaluate, keyed by priority.
  waf_rules = {
    3000 = { expr = "sqli-v33-stable", desc = "Block SQL injection (OWASP CRS)" }
    3010 = { expr = "xss-v33-stable", desc = "Block cross-site scripting (OWASP CRS)" }
    3020 = { expr = "lfi-v33-stable", desc = "Block local file inclusion (OWASP CRS)" }
    3030 = { expr = "rce-v33-stable", desc = "Block remote code execution (OWASP CRS)" }
    3040 = { expr = "scannerdetection-v33-stable", desc = "Block scanner/recon traffic (OWASP CRS)" }
  }

  # In non-enforcing environments, WAF/geo rules run in preview (log-only) mode.
  preview = !var.enforce
}

resource "google_compute_security_policy" "this" {
  project     = var.project_id
  name        = var.policy_name
  description = var.description
  type        = "CLOUD_ARMOR"

  dynamic "adaptive_protection_config" {
    for_each = var.enable_adaptive_protection ? [1] : []
    content {
      layer_7_ddos_defense_config {
        enable          = true
        rule_visibility = "STANDARD"
      }
    }
  }

  # --- Optional allowlist: trusted ranges bypass WAF/rate limiting. ---
  dynamic "rule" {
    for_each = length(var.allowlisted_ip_ranges) > 0 ? [1] : []
    content {
      action      = "allow"
      priority    = 1000
      description = "Allow trusted/corporate egress ranges"
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.allowlisted_ip_ranges
        }
      }
    }
  }

  # --- Rate limiting / rate-based ban per client IP. ---
  rule {
    action      = "rate_based_ban"
    priority    = 2000
    description = "Throttle and ban abusive client IPs"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = var.rate_limit_ban_duration_sec
      rate_limit_threshold {
        count        = var.rate_limit_threshold_count
        interval_sec = var.rate_limit_interval_sec
      }
    }
  }

  # --- Preconfigured OWASP WAF rules. ---
  dynamic "rule" {
    for_each = local.waf_rules
    content {
      action      = "deny(403)"
      priority    = rule.key
      description = rule.value.desc
      preview     = local.preview
      match {
        expr {
          expression = "evaluatePreconfiguredWaf('${rule.value.expr}', {'sensitivity': ${var.waf_sensitivity}})"
        }
      }
    }
  }

  # --- Optional geo-restriction. ---
  dynamic "rule" {
    for_each = length(var.blocked_country_codes) > 0 ? [1] : []
    content {
      action      = "deny(403)"
      priority    = 4000
      description = "Geo-restriction: block selected country codes"
      preview     = local.preview
      match {
        expr {
          expression = join(" || ", [for c in var.blocked_country_codes : "origin.region_code == '${c}'"])
        }
      }
    }
  }

  # --- Default rule (required): allow everything not matched above. ---
  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow rule"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
