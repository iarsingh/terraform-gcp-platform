# Remote state in GCS. State is isolated per environment via the `prefix`.
#
# Bucket naming convention: <org-prefix>-tfstate-<purpose>
#   e.g. acme-tfstate-platform  (single versioned bucket, one prefix per env)
#
# Bootstrap the bucket ONCE before the first `terraform init`:
#   ./scripts/bootstrap-state-bucket.sh acme-tfstate-platform europe-west1
#
# This block is intentionally left commented so the repo can be initialized
# with `terraform init -backend=false` for offline validation. Uncomment and
# fill in the real bucket to use remote state.
#
# terraform {
#   backend "gcs" {
#     bucket = "acme-tfstate-platform"
#     prefix = "environments/dev"
#   }
# }
