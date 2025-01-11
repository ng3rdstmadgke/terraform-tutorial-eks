SCRIPT_DIR := $(shell cd $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) && pwd)
PROJECT_NAME ?=
STAGE ?=
COMPONENT ?=
COMMON_BACKEND_CONFIG := $(SCRIPT_DIR)/terraform/components/tfvars/backend.tfvars
COMMON_TFVARS := $(SCRIPT_DIR)/terraform/components/tfvars/common.tfvars
COMPONENT_DIR := $(SCRIPT_DIR)/terraform/components/$(COMPONENT)
COMPONENT_TFVARS=$(COMPONENT_DIR)/tfvars/$(STAGE).tfvars
TFPLAN_DIR := $(SCRIPT_DIR)/.tfplan/$(COMPONENT)/

.PHONY: option-parser
option-parser:
	@if [ -z "$(PROJECT_NAME)" ]; then \
		echo "[Err] PROJECT_NAME is required"; \
		exit 1; \
	fi
	@if [ -z "$(STAGE)" ]; then \
		echo "[Err] STAGE is required"; \
		exit 1; \
	fi
	@if [ -z "$(COMPONENT)" ]; then \
		echo "[Err] COMPONENT is required"; \
		exit 1; \
	fi

.PHONY: tf-validate 
tf-validate: option-parser ## terraform validate
	terraform -chdir=$(COMPONENT_DIR) validate

.PHONY: tf-init
tf-init: tf-validate ## terraform init
	terraform -chdir=$(COMPONENT_DIR) init \
	  -reconfigure \
	  -backend-config $(COMMON_BACKEND_CONFIG) \
	  -backend-config "key=$(PROJECT_NAME)/$(STAGE)/$(COMPONENT)/terraform.tfstate"

.PHONY: tf-plan
tf-plan: tf-init ## terraform plan
	mkdir -p $(TFPLAN_DIR)
	terraform -chdir=$(COMPONENT_DIR) plan \
	  -var "project_name=$(PROJECT_NAME)" \
	  -var "stage=$(STAGE)" \
	  -var-file=$(COMMON_TFVARS) \
	  -var-file=$(COMPONENT_TFVARS) \
	  -out $(TFPLAN_DIR)/.plan
	terraform -chdir=$(COMPONENT_DIR) show -json $(TFPLAN_DIR)/.plan > $(TFPLAN_DIR)/plan.tfgraph

.PHONY: tf-apply
tf-apply: tf-init ## terraform apply
	terraform -chdir=$(COMPONENT_DIR) apply \
	  -var "project_name=$(PROJECT_NAME)" \
	  -var "stage=$(STAGE)" \
	  -var-file=$(COMMON_TFVARS) \
	  -var-file $(COMPONENT_TFVARS) \
		--auto-approve

.PHONY: tf-output
tf-output: tf-init ## terraform apply
	terraform -chdir=$(COMPONENT_DIR) output

.PHONY: tf-destroy
tf-destroy: tf-init ## terraform destroy
	terraform -chdir=$(COMPONENT_DIR) destroy \
	  -var "project_name=$(PROJECT_NAME)" \
	  -var "stage=$(STAGE)" \
	  -var-file=$(COMMON_TFVARS) \
	  -var-file $(COMPONENT_TFVARS) \
		--auto-approve

.PHONY: help
.DEFAULT_GOAL := help
help: ## HELP表示
	@grep --no-filename -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'