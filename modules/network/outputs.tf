output "network_id" {
  description = "The VPC network ID."
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "The VPC network name."
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "The VPC network self link."
  value       = google_compute_network.this.self_link
}

output "subnets" {
  description = "Map of subnet name to key attributes (id, self_link, region, cidr, secondary range names)."
  value = {
    for name, s in google_compute_subnetwork.this : name => {
      id            = s.id
      self_link     = s.self_link
      region        = s.region
      ip_cidr_range = s.ip_cidr_range
      secondary_range_names = [
        for r in s.secondary_ip_range : r.range_name
      ]
    }
  }
}

output "router_name" {
  description = "The Cloud Router name."
  value       = google_compute_router.this.name
}

output "nat_name" {
  description = "The Cloud NAT name."
  value       = google_compute_router_nat.this.name
}
