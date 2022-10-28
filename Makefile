SHELL := $(shell which bash)

MODULES_DIR=modules
MODULENAME_PATTERN=^[0-9a-z-]*$$

ifeq (module,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

ifdef TERM
BOLD=$(shell tput bold)
RED=$(shell tput setaf 1)
GREEN=$(shell tput setaf 2)
YELLOW=$(shell tput setaf 3)
RESET=$(shell tput sgr0)
endif

.PHONY: module

module :
	@MODULENAME=$(RUN_ARGS); \
	MODULES_DIR=$(MODULES_DIR); \
	MODULENAME_PATTERN=$(MODULENAME_PATTERN); \
	if [ -z $$MODULENAME ]; then \
		echo "$(BOLD)$(RED)No module name provided.$(RESET)"; \
		echo "$(BOLD)Example usage: \`make module my-module\`$(RESET)"; \
		exit 1; \
	elif [[ ! $$MODULENAME =~ $$MODULENAME_PATTERN ]]; then \
		echo "$(BOLD)$(RED)Module name must match \'$$MODULENAME_PATTERN'.$(RESET)"; \
		echo "$(BOLD)Example usage: \`make module my-module\`$(RESET)"; \
		exit 1; \
	elif [ -d $$MODULES_DIR/$$MODULENAME ]; then \
		echo "$(BOLD)$(RED)Module $$MODULENAME already exists.$(RESET)"; \
		exit 1; \
	else \
		MODULENAME=$$MODULENAME gomplate --input-dir=.template --output-dir=$$MODULES_DIR/$$MODULENAME; \
		echo "$(BOLD)$(GREEN)$$MODULES_DIR/$$MODULENAME$(RESET)"; \
		git checkout -b "$$MODULENAME"; \
		cd $$MODULES_DIR/$$MODULENAME; \
		make test; \
	fi
