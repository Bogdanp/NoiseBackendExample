ARCH=$(shell uname -m)

.PHONY: all
all: NoiseBackendExample/resources/core-${ARCH}.zo NoiseBackendExample/SerdeRecords.swift

NoiseBackendExample/resources/core-${ARCH}.zo: core/*.rkt
	mkdir -p NoiseBackendExample/resources
	raco ctool --mods $@ core/main.rkt

NoiseBackendExample/SerdeRecords.swift: core/*.rkt
	racket core/main.rkt > $@
