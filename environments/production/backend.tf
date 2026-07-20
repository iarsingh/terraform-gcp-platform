# Remote state in GCS. State is isolated per environment via the `prefix`.
#
# Bucket naming convention: <org-prefix>-tfstate-<purpose>
#   e.g. acme-tfstate-platform  (single versioned bucket, one prefix per env)
#
# Bootstrap the bucket ONCE before the first `terraform init`:
#   ./scripts/bootstrap-state-bucket.sh acme-tfstate-platform europe-west1
#
# Production state should live in its own bucket with restricted IAM and
# object versioning enabled (see scripts/bootstrap-state-bucket.sh). This block
# is left commented so the repo initializes with `-backend=false` for offline
# validation. Uncomment and fill in the real bucket to use remote state.
#
# terraform {
#   backend "gcs" {
#     bucket = "acme-tfstate-platform-prod"
#     prefix = "environments/production"
#   }
# }
