# Conftest / OPA policies for GKE hardening.
#
# Evaluate against a Terraform plan rendered to JSON:
#   terraform plan -out=tfplan.binary
#   terraform show -json tfplan.binary > tfplan.json
#   conftest test --policy policies tfplan.json
#
package main

import future.keywords.in

# Collect every planned google_container_cluster resource (create/update).
gke_clusters[r] {
	some r in input.resource_changes
	r.type == "google_container_cluster"
	r.change.actions[_] != "delete"
}

# ---------------------------------------------------------------------------
# Deny clusters whose nodes are not private.
# ---------------------------------------------------------------------------
deny[msg] {
	some r in gke_clusters
	pcc := r.change.after.private_cluster_config[_]
	pcc.enable_private_nodes != true
	msg := sprintf("GKE cluster '%s' must set private_cluster_config.enable_private_nodes = true", [r.address])
}

# Deny clusters that declare no private_cluster_config at all.
deny[msg] {
	some r in gke_clusters
	not r.change.after.private_cluster_config
	msg := sprintf("GKE cluster '%s' must define private_cluster_config (private nodes are required)", [r.address])
}

# ---------------------------------------------------------------------------
# Deny use of the default compute service account on node pools.
# ---------------------------------------------------------------------------
deny[msg] {
	some r in input.resource_changes
	r.type == "google_container_node_pool"
	r.change.actions[_] != "delete"
	nc := r.change.after.node_config[_]
	contains(nc.service_account, "-compute@developer.gserviceaccount.com")
	msg := sprintf("Node pool '%s' must not use the default compute service account", [r.address])
}

# Deny node pools that do not enable Workload Identity metadata mode.
deny[msg] {
	some r in input.resource_changes
	r.type == "google_container_node_pool"
	r.change.actions[_] != "delete"
	nc := r.change.after.node_config[_]
	wmc := nc.workload_metadata_config[_]
	wmc.mode != "GKE_METADATA"
	msg := sprintf("Node pool '%s' must set workload_metadata_config.mode = GKE_METADATA", [r.address])
}
