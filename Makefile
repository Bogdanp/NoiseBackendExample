ARCH=$(shell uname -m)

.PHONY: all
all: NoiseBackendExample/resources/core-${ARCH}.zo NoiseBackendExample/Record.swift

NoiseBackendExample/resources/core-${ARCH}.zo: core/*.rkt
	mkdir -p NoiseBackendExample/resources
	raco ctool --mods $@ core/main.rkt

NoiseBackendExample/Record.swift: core/*.rkt
	raco noise-serde-codegen core/main.rkt > $@
