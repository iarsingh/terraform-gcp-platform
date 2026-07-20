variable "project_id" {
  description = "Project ID that hosts the Artifact Registry repositories."
  type        = string
}

variable "location" {
  description = "Region for the repositories (e.g. europe-west1). Keep close to GKE to reduce pull latency and egress."
  type        = string
}

variable "repositories" {
  description = "Artifact Registry repositories to create, keyed by repository ID."
  type = map(object({
    format      = optional(string, "DOCKER")
    description = optional(string, "")
    # Keep only the N most recent versions; older untagged versions are deleted.
    keep_most_recent = optional(number, 10)
    # Delete untagged images older than this many days.
    delete_untagged_older_than_days = optional(number, 30)
    immutable_tags                  = optional(bool, false)
    labels                          = optional(map(string), {})
  }))
}

variable "reader_members" {
  description = "IAM members granted read (pull) access across all repositories (e.g. GKE node SA)."
  type        = list(string)
  default     = []
}

variable "writer_members" {
  description = "IAM members granted write (push) access across all repositories (e.g. CI service account)."
  type        = list(string)
  default     = []
}
