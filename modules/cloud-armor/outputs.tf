output "policy_id" {
  description = "The Cloud Armor security policy ID."
  value       = google_compute_security_policy.this.id
}

output "policy_name" {
  description = "The Cloud Armor security policy name (attach to backend services)."
  value       = google_compute_security_policy.this.name
}

output "policy_self_link" {
  description = "The Cloud Armor security policy self link."
  value       = google_compute_security_policy.this.self_link
}

output "enforcing" {
  description = "Whether WAF/geo rules are enforced (true) or in preview/log-only mode (false)."
  value       = var.enforce
}
