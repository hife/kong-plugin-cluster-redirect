OS := $(shell uname)

DEV_ROCKS = "busted 2.0.rc13" "luacheck 0.20.0" "lua-llthreads2 0.1.5"
BUSTED_ARGS ?= -v
TEST_CMD ?= busted $(BUSTED_ARGS)

.PHONY: install dev lint test

install:
	@luarocks make kong-plugin-cluster-redirect-*.rockspec \

dev: install
	@for rock in $(DEV_ROCKS) ; do \
	  if luarocks list --porcelain $$rock | grep -q "installed" ; then \
	    echo $$rock already installed, skipping ; \
	  else \
	    echo $$rock not found, installing via luarocks... ; \
	    luarocks install $$rock ; \
	  fi \
	done;

lint:
	@luacheck -q kong \
		--std 'busted' \
		--globals 'require' \
		--globals 'ngx' \
		--no-redefined \
		--no-unused-args

test:
	@$(TEST_CMD) spec

