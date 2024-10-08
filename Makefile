ARCH=$(shell uname -m)

APP_SRC=NoiseBackendExample
RKT_SRC=core

RESOURCES_PATH=${APP_SRC}/res
RUNTIME_NAME=runtime-${ARCH}
RUNTIME_PATH=${RESOURCES_PATH}/${RUNTIME_NAME}

.PHONY: all
all: ${RESOURCES_PATH}/core-${ARCH}.zo ${APP_SRC}/Backend.swift

.PHONY: clean
clean:
	rm -r ${RESOURCES_PATH}

${APP_SRC}/res/core-${ARCH}.zo: ${RKT_SRC}/*.rkt
	mkdir -p ${RESOURCES_PATH}
	rm -fr ${RUNTIME_PATH}
	raco ctool \
	  --runtime ${RUNTIME_PATH} \
	  --runtime-access ${RUNTIME_NAME} \
	  --mods $@ ${RKT_SRC}/main.rkt

${APP_SRC}/Backend.swift: ${RKT_SRC}/*.rkt
	raco noise-serde-codegen ${RKT_SRC}/main.rkt > $@
