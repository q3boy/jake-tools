REPORTER ?= dot

all: build

build:
	@./node_modules/.bin/coffee -b -c ./jake-tools.coffee > /dev/null 2>&1
	@./node_modules/.bin/yaml2json -sp ./package.yaml > /dev/null 2>&1
	@echo "build done"

clean:
	@rm -f jake-tools.js
	@rm -f package.json
	@echo "clean done"

.PHONY: all
