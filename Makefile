# n8n-Pi OS Makefile
# Author: Stefano Amorelli <stefano@amorelli.tech>
# Build custom Raspberry Pi OS with n8n pre-installed

.PHONY: help build clean release check version download-base lint flash dev

# Configuration
CONFIG_FILE := config.yml
SCRIPTS_DIR := scripts

# Export CONFIG_FILE for scripts to use
export CONFIG_FILE

help: ## Show this help
	@$(SCRIPTS_DIR)/help.sh

build: check ## Build n8n-Pi OS image
	@$(SCRIPTS_DIR)/build.sh


clean: ## Clean build artifacts
	@$(SCRIPTS_DIR)/clean.sh

release: build ## Create release package
	@$(SCRIPTS_DIR)/release.sh

check: ## Check build requirements
	@$(SCRIPTS_DIR)/check.sh

version: ## Show version
	@$(SCRIPTS_DIR)/version.sh

download-base: ## Download Raspberry Pi OS base image
	@$(SCRIPTS_DIR)/download-base.sh

lint: ## Run linting locally
	@$(SCRIPTS_DIR)/lint.sh

flash: ## Flash image to SD card
	@$(SCRIPTS_DIR)/flash.sh

dev: ## Development mode - test scripts locally
	@$(SCRIPTS_DIR)/dev.sh