# Conftest / OPA guardrails that only apply to the production workspace/plan.
#
# Usage:
#   conftest test --policy policies --namespace main tfplan.json
#
package main

import future.keywords.in

# Heuristic: a plan is "production" if any resource name/label references prod.
is_production {
	some r in input.resource_changes
	labels := r.change.after.resource_labels
	labels.env == "production"
}

is_production {
	some r in input.resource_changes
	r.type == "google_container_cluster"
	contains(r.change.after.name, "prod")
}

# ---------------------------------------------------------------------------
# Production GKE clusters must have deletion protection enabled.
# ---------------------------------------------------------------------------
deny[msg] {
	is_production
	some r in input.resource_changes
	r.type == "google_container_cluster"
	r.change.actions[_] != "delete"
	r.change.after.deletion_protection != true
	msg := sprintf("Production cluster '%s' must have deletion_protection = true", [r.address])
}

# ---------------------------------------------------------------------------
# Production GKE control plane must be private (no public endpoint).
# ---------------------------------------------------------------------------
deny[msg] {
	is_production
	some r in input.resource_changes
	r.type == "google_container_cluster"
	r.change.actions[_] != "delete"
	pcc := r.change.after.private_cluster_config[_]
	pcc.enable_private_endpoint != true
	msg := sprintf("Production cluster '%s' must set enable_private_endpoint = true", [r.address])
}

# ---------------------------------------------------------------------------
# Required labels on all label-bearing resources (governance / cost tracking).
# ---------------------------------------------------------------------------
required_labels := {"env", "managed_by", "team"}

deny[msg] {
	some r in input.resource_changes
	labels := r.change.after.resource_labels
	some required in required_labels
	not labels[required]
	msg := sprintf("Resource '%s' is missing required label '%s'", [r.address, required])
}
