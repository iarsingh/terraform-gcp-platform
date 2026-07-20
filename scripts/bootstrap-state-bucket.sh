#!/usr/bin/env bash
#
# Bootstrap the GCS bucket that holds remote Terraform state.
#
# Creates (idempotently) a bucket with:
#   - object versioning enabled (state rollback via prior generations)
#   - uniform bucket-level access (no per-object ACLs)
#   - public access prevention enforced
#   - Google-managed encryption (add a CMEK with `gcloud storage buckets update`
#     if you require customer-managed keys)
#
# Usage:
#   ./scripts/bootstrap-state-bucket.sh <bucket-name> [location] [project-id]
#
# Example:
#   ./scripts/bootstrap-state-bucket.sh acme-tfstate-platform europe-west1 acme-seed
#
set -euo pipefail

BUCKET="${1:?Usage: bootstrap-state-bucket.sh <bucket-name> [location] [project-id]}"
LOCATION="${2:-europe-west1}"
PROJECT="${3:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "${PROJECT}" || "${PROJECT}" == "(unset)" ]]; then
  echo "ERROR: no project provided and none configured (gcloud config set project ...)." >&2
  exit 1
fi

echo "Project : ${PROJECT}"
echo "Bucket  : gs://${BUCKET}"
echo "Location: ${LOCATION}"

# Create the bucket only if it does not already exist (idempotent).
if gcloud storage buckets describe "gs://${BUCKET}" --project "${PROJECT}" >/dev/null 2>&1; then
  echo "Bucket already exists; ensuring settings are correct."
else
  echo "Creating bucket..."
  gcloud storage buckets create "gs://${BUCKET}" \
    --project "${PROJECT}" \
    --location "${LOCATION}" \
    --uniform-bucket-level-access \
    --public-access-prevention
fi

echo "Enabling object versioning (state history / rollback)..."
gcloud storage buckets update "gs://${BUCKET}" --versioning

echo "Applying a lifecycle rule to keep the 10 newest noncurrent state versions..."
TMP_LIFECYCLE="$(mktemp)"
cat >"${TMP_LIFECYCLE}" <<'JSON'
{
  "rule": [
    {
      "action": { "type": "Delete" },
      "condition": { "numNewerVersions": 10, "isLive": false }
    }
  ]
}
JSON
gcloud storage buckets update "gs://${BUCKET}" --lifecycle-file="${TMP_LIFECYCLE}"
rm -f "${TMP_LIFECYCLE}"

echo "Done. Configure the backend in environments/<env>/backend.tf with:"
echo "  bucket = \"${BUCKET}\""
echo "  prefix = \"environments/<env>\""
