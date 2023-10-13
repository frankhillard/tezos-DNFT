default: help

PROJECT=$(notdir $(CURDIR))

# Perl Colors, with fallback if tput command not available
GREEN  := $(shell command -v tput >/dev/null 2>&1 && tput -Txterm setaf 2 || echo "")
BLUE   := $(shell command -v tput >/dev/null 2>&1 && tput -Txterm setaf 4 || echo "")
WHITE  := $(shell command -v tput >/dev/null 2>&1 && tput -Txterm setaf 7 || echo "")
YELLOW := $(shell command -v tput >/dev/null 2>&1 && tput -Txterm setaf 3 || echo "")
RESET  := $(shell command -v tput >/dev/null 2>&1 && tput -Txterm sgr0 || echo "")

# Add help text after each target name starting with '\#\#'
# A category can be added with @category
HELP_FUN = \
    %help; \
    while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-zA-Z\-]+)\s*:.*\#\#(?:@([a-zA-Z\-]+))?\s(.*)$$/ }; \
    print "usage: make [target]\n\n"; \
    for (sort keys %help) { \
    print "${WHITE}$$_:${RESET}\n"; \
    for (@{$$help{$$_}}) { \
    $$sep = " " x (32 - length $$_->[0]); \
    print "  ${YELLOW}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
    }; \
    print "\n"; }

help:
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)

#######################################
#              PROJECT                #
#######################################

all: install compile fixtures prepare upload deploy ##@Project - Runs all the deployment chain from scratch

nuke-all: ##@Project - Deletes IMPORTANT FILES & FOLDERS to reset to initial state
	@echo "Are you sure you want to DELETE IMPORTANT FILES from this folder to RESET EVERYTHING to initial state ? [y/N]" \
		&& read ans && if [ $${ans:-'N'} = 'y' ]; then rm -rf ./web/node_modules/ ./compiled/* ./web/deployments/* ; fi

#######################################
#            CONTRACTS                #
#######################################
ifndef LIGO
LIGO=docker run --platform linux/amd64 --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:0.58.0
endif

NPM=npm --silent --prefix ./web

compile = $(LIGO) compile contract ./src/$(1) -o ./compiled/$(2) $(3)
# ^ Compile contracts to Michelson or Micheline

test-ligo = $(LIGO) run test ./tests/$(1)
# ^ Run the given LIGO Test file

compile: ##@Contracts - Compile LIGO contracts
	@if [ ! -d ./compiled ]; then mkdir ./compiled ; fi
	@echo "Compiling contracts..."
	@$(call compile,collection/main.mligo,collection.tz)
	@$(call compile,collection/main.mligo,collection.json,--michelson-format json)
	@$(call compile,marketplace/main.mligo,marketplace.tz)
	@$(call compile,marketplace/main.mligo,marketplace.json,--michelson-format json)

test-ligo: test-ligo-collection test-ligo-marketplace  ##@Contracts - Run all LIGO tests

test-ligo-collection: ##@Contracts - Run Collection LIGO tests (make test-ligo-collection SUITE=pause)
ifndef SUITE
	@$(call test-ligo,collection/change_admin.test.mligo)
	@$(call test-ligo,collection/approve_admin.test.mligo)
	@$(call test-ligo,collection/authorize.test.mligo)
	@$(call test-ligo,collection/unauthorize.test.mligo)
	@$(call test-ligo,collection/switch_whitelist_usage.test.mligo)
	@$(call test-ligo,collection/premint.test.mligo)
##	@$(call test-ligo,collection/retrieve_locked_xtz.test.mligo)
	@$(call test-ligo,collection/change_collection_metadata.test.mligo)
	@$(call test-ligo,collection/change_token_metadata.test.mligo)
	@$(call test-ligo,collection/update_tokens.test.mligo)
	@$(call test-ligo,collection/increase_reputation.test.mligo)
else
	@$(call test-ligo,collection/$(SUITE).test.mligo)
endif

test-ligo-marketplace: ##@Contracts - Run Marketplace LIGO tests
	@$(call test-ligo,marketplace.test.mligo)

test-integration: ##@Contracts - Run integration tests
	@$(MAKE) deploy
	@$(NPM) run test

clean: ##@Contracts - Contracts clean up
	@echo "Are you sure you want to DELETE ALL COMPILED CONTRACT FILES from your Compiled folder ? [y/N]" \
		&& read ans && if [ $${ans:-'N'} = 'y' ]; then rm -rf compiled/* ; fi

#######################################
#            SCRIPTS                  #
#######################################
install: ##@Scripts - Install NPM dependencies
	@if [ ! -f ./.env ]; then cp .env.dist .env ; fi
	@$(LIGO) install
	@$(NPM) ci

lint: ## lint code
	@$(NPM) run lint

lint-fix: ## autofix lint code
	@$(NPM) run lint:fix

deploy: ##@Scripts - Deploy contracts
	@./web/scripts/deploy

#######################################
#            SANDBOX                  #
#######################################
sandbox-start: ##@Sandbox - Start Flextesa sandbox
	@./web/scripts/run-sandbox $(PROJECT)

sandbox-stop: ##@Sandbox - Stop Flextesa sandbox
	@docker stop $(PROJECT)-sandbox
