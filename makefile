# ------------- Common --------------

# Favor local npm devDependencies if they are installed
export PATH := node_modules/.bin:$(PATH)

# Use `PHONY` because target name is not an actual file
.PHONY: build info

# Builds everything. No recipe required.
# A build is necessary before parcel commands.
# Users could just run `spago build` instead of `make build`,
# unless they want local npm version and don't want to run `npx spago build`.
build:
	spago build

# Prints version and path information.
# For troubleshooting version mismatches.
info:
	which purs
	purs --version
	which spago
	spago version
	which parcel
	parcel --version

# Tests if recipe actually exists.
# This should be a dependency of all entry targets
recipes/%:
	test -d $* || { echo "Recipe $* does not exist"; exit 1;}

# -------- Pattern matching strategy -----------

# Usage:
#
# make Template-run
# make Template-serve
# make Template-buildDev
# make Template-buildProd

# Targets for all recipe build operations
recipes := $(shell ls recipes)
recipesRun := $(foreach r,$(recipes),$(r)-run)
recipesServe := $(foreach r,$(recipes),$(r)-serve)
recipesBuildDev := $(foreach r,$(recipes),$(r)-buildDev)
recipesBuildProd := $(foreach r,$(recipes),$(r)-buildProd)

# Use `PHONY` because target name is not an actual file
.PHONY: recipesRun recipesServe recipesBuildDev recipesBuildProd buildAllDev buildAllProd

# Helper functions for generating paths
main = $1.Main
recipeDir = recipes/$1

devDir = $(call recipeDir,$1)/dev
devHtml = $(call devDir,$1)/index.html
devDistDir = $(call recipeDir,$1)/dev-dist

prodDir = $(call recipeDir,$1)/prod
prodHtml = $(call prodDir,$1)/index.html
prodJs = $(call prodDir,$1)/index.js
prodDistDir = $(call recipeDir,$1)/prod-dist

# Runs recipe as node.js console app
%-run: $(call recipeDir,%)
	spago run --main $(call main,$*)

# Launches recipe in browser
%-serve: $(call recipeDir,%) build
	parcel $(call devHtml,$*) --out-dir $(call devDistDir,$*) --open

# Uses parcel to quickly create an unminified build.
# For CI purposes.
%-buildDev: export NODE_ENV=development
%-buildDev: build $(call recipeDir,%)
	parcel build $(call devHtml,$*) --out-dir $(call devDistDir,$*) --no-minify --no-source-maps

# How to make prodDir
$(call prodDir,$(recipes)):
	mkdir -p $@

# How to make prodHtml
recipes/%/prod/index.html: $(call prodDir,%)
	cp $(call devHtml,$*) $(call prodDir,$*)

# Creates a minified production build.
# For reference.
%-buildProd: $(call recipeDir,%) $(call prodHtml,%)
	spago bundle-app --main $(call main,$*) --to $(call prodJs,$*)
	parcel build $(call prodHtml,$*) --out-dir $(call prodDistDir,$*)

# Creates all dev builds - for CI
buildAllDev: $(recipesBuildDev)

# Creates all prod builds - for CI
buildAllProd: $(recipesBuildProd)