ARCH=$(shell uname -m)

NoiseBackendExample/resources/core-${ARCH}.zo: core/*.rkt
	mkdir -p NoiseBackendExample/resources
	raco ctool --mods $@ core/main.rkt
