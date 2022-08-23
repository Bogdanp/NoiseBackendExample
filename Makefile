ARCH=$(shell uname -m)
APP_SRC=NoiseBackendExample
RKT_SRC=core

.PHONY: all
all: ${APP_SRC}/resources/core-${ARCH}.zo ${APP_SRC}/Record.swift

${APP_SRC}/resources/core-${ARCH}.zo: ${RKT_SRC}/*.rkt
	mkdir -p ${APP_SRC}/resources
	raco ctool --runtime ${APP_SRC}/resources/runtime --mods $@ ${RKT_SRC}/main.rkt

${APP_SRC}/Record.swift: ${RKT_SRC}/*.rkt
	raco noise-serde-codegen ${RKT_SRC}/main.rkt > $@
