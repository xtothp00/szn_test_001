#!/usr/bin/env bash
set -ex

printf "building the %s application...\n" ${APP_NAME:=app}

BUILD_CMD="go build -v -o ${APP_NAME:=app} ."
BUILD_CONTAINER_IMAGE="docker.io/library/golang:alpine"

# Building locally if possible.
if command -v go &> /dev/zero; then
# Env var STATIC enbales the static build. It can hold any value, only the emptiness is evaluated.
    if [ -n "${STATIC}" ]; then
        BUILD_CMD="CGO_ENABLED=0 ${BUILD_CMD}"
    fi
    eval ${BUILD_CMD}

# Building using golang contair utilizing podman or docker engine.
else
    CONTAINER_ENGINE_ARGS=" --rm -v "$PWD":/usr/src/app:z -w /usr/src/app"
    if [ -n "${STATIC}" ]; then
        CONTAINER_ENGINE_ARGS="${CONTAINER_ENGINE_ARGS} -e=CGO_ENABLED=0"
    fi

    if command -v podman &> /dev/zero; then
        podman run ${CONTAINER_ENGINE_ARGS} ${BUILD_CONTAINER_IMAGE} ${BUILD_CMD}
    elif command -v docker &> /dev/zero; then
        docker run ${CONTAINER_ENGINE_ARGS} ${BUILD_CONTAINER_IMAGE} ${BUILD_CMD}
    fi
fi
printf "building the test image...\n"
if [ -n "${STATIC}" ]; then
    CONTAINER=$(buildah from ${STATIC_FROM:=scratch})
    buildah copy ${CONTAINER} ${APP_NAME:=app} /bin/${APP_NAME:=app}
else
    echo CONTAINER=$(buildah from ${BUILD_CONTAINER_IMAGE})
    CONTAINER=$(buildah from ${BUILD_CONTAINER_IMAGE})
    PREV_WORKINGDIR=$(buildah run -- ${CONTAINER} pwd)
    buildah copy ${CONTAINER} go.mod go.sum main.go /src
    buildah config --workingdir /src ${CONTAINER}
    buildah run -- ${CONTAINER} ${BUILD_CMD}
    buildah run -- ${CONTAINER} cp ${APP_NAME:=app} /bin/${APP_NAME:=app}
    buildah config --workingdir ${PREV_WORKINGDIR} ${CONTAINER}
fi

buildah config --port 8090 ${CONTAINER}
buildah config --cmd /bin/${APP_NAME:=app} ${CONTAINER}

buildah commit --format docker ${CONTAINER} szn_test_001:${TAG:=1}
