# Run Terraform and Ansible from the repo root.
#
# Extra options:
#   make apply TF_ARGS="-auto-approve"
#   make deploy ANSIBLE_ARGS="-v"

TF_DIR      := terraform
ANSIBLE_DIR := ansible

TF_ARGS      ?=
ANSIBLE_ARGS ?=

MAKEFLAGS += --no-print-directory

TF      := terraform -chdir=$(TF_DIR)
# ansible.cfg is only read from the current directory, hence the cd.
ANSIBLE := cd $(ANSIBLE_DIR) &&

.DEFAULT_GOAL := help
.PHONY: help setup up init fmt validate plan apply output destroy galaxy syntax ping wait deploy

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} \
		/^##@ / {printf "\n%s\n", substr($$0, 5)} \
		/^[a-z-]+:.*## / {printf "  %-10s %s\n", $$1, $$2}' $(firstword $(MAKEFILE_LIST))

##@ Full workflow

setup: ## Install Terraform providers and Ansible collections
	$(MAKE) init
	$(MAKE) galaxy

up: ## Create the VMs, wait for SSH, then deploy the cluster
	$(MAKE) apply
	$(MAKE) wait
	$(MAKE) deploy

##@ Terraform (TF_ARGS="...")

init: ## terraform init
	$(TF) init $(TF_ARGS)

fmt: ## terraform fmt
	$(TF) fmt $(TF_ARGS)

validate: ## terraform validate
	$(TF) validate $(TF_ARGS)

plan: ## terraform plan
	$(TF) plan $(TF_ARGS)

apply: ## terraform apply (also generates ansible/inventory.yml)
	$(TF) apply $(TF_ARGS)

output: ## terraform output
	$(TF) output $(TF_ARGS)

destroy: ## terraform destroy
	$(TF) destroy $(TF_ARGS)

##@ Ansible (ANSIBLE_ARGS="...")

galaxy: ## Install collections from requirements.yml
	$(ANSIBLE) ansible-galaxy collection install -r requirements.yml $(ANSIBLE_ARGS)

syntax: ## Check the playbook syntax
	$(ANSIBLE) ansible-playbook site.yml --syntax-check $(ANSIBLE_ARGS)

ping: ## Test the connection to the nodes
	$(ANSIBLE) ansible all -m ping $(ANSIBLE_ARGS)

wait: ## Wait until the nodes accept connections (5 min max)
	$(ANSIBLE) ansible all -m wait_for_connection -a "timeout=300"

deploy: ## Run site.yml (kubeadm cluster + addons)
	$(ANSIBLE) ansible-playbook site.yml $(ANSIBLE_ARGS)
