# Terraform GCP Landing Zone — developer convenience targets.
#
# Most targets operate per environment. Override ENV to switch:
#   make plan ENV=staging
#
# Offline validation (no GCP credentials needed):
#   make fmt validate

ENV        ?= dev
ENV_DIR     = environments/$(ENV)
TF          = terraform
MODULES     = $(wildcard modules/*/.)
ENVS        = dev staging production

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: fmt
fmt: ## Format all Terraform files
	$(TF) fmt -recursive

.PHONY: fmt-check
fmt-check: ## Check formatting without modifying files
	$(TF) fmt -check -recursive

.PHONY: validate
validate: ## init -backend=false + validate for every module and environment
	@for d in modules/*/ environments/*/; do \
		echo "==> $$d"; \
		$(TF) -chdir=$$d init -backend=false -input=false >/dev/null && \
		$(TF) -chdir=$$d validate -no-color || exit 1; \
	done

.PHONY: init
init: ## terraform init for the selected ENV
	$(TF) -chdir=$(ENV_DIR) init -input=false

.PHONY: plan
plan: ## terraform plan for the selected ENV (make plan ENV=staging)
	$(TF) -chdir=$(ENV_DIR) plan -input=false

.PHONY: plan-dev
plan-dev: ## Plan the dev environment
	$(MAKE) plan ENV=dev

.PHONY: plan-staging
plan-staging: ## Plan the staging environment
	$(MAKE) plan ENV=staging

.PHONY: plan-production
plan-production: ## Plan the production environment
	$(MAKE) plan ENV=production

.PHONY: apply-dev
apply-dev: ## Apply dev with an interactive confirmation
	@echo "About to APPLY to the DEV environment."
	@read -p "Type 'apply-dev' to continue: " ans; \
		[ "$$ans" = "apply-dev" ] || { echo "Aborted."; exit 1; }
	$(TF) -chdir=environments/dev apply -input=false

.PHONY: lint
lint: ## Run tflint / tfsec / checkov if installed (via scripts/validate.sh)
	./scripts/validate.sh

.PHONY: clean
clean: ## Remove local .terraform dirs, lock files, and plan artifacts
	find . -type d -name ".terraform" -prune -exec rm -rf {} +
	find . -type f -name ".terraform.lock.hcl" -delete
	find . -type f \( -name "*.tfplan" -o -name "tfplan.*" \) -delete
	@echo "Cleaned Terraform working files."
