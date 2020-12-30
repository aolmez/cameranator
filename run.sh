#!/usr/bin/env bash

set -e -x

pushd "$(pwd)"

function teardown() {
  docker-compose down --remove-orphans --volumes || true
  popd >/dev/null 2>&1
}
trap teardown EXIT

export DOCKER_BUILDKIT=1

docker-compose up -d postgres hasura

export HASURA_GRAPHQL_ENDPOINT="http://host.docker.internal:8079/"

cd persistence/hasura

while ! hasura migrate apply; do
  sleep 1
done

while ! hasura metadata apply; do
  sleep 1
done

while ! hasura seeds apply; do
  sleep 1
done

popd

CCTV_EVENTS_QUOTA=1
CCTV_EVENTS_PATH="$(pwd)/temp_data/events"

CCTV_SEGMENTS_QUOTA=1
CCTV_SEGMENTS_PATH="$(pwd)/temp_data/segments"
CCTV_SEGMENT_DURATION=10

CCTV_MOTION_CONFIGS="$(pwd)/motion-configs"

DISABLE_NVIDIA=1

export CCTV_EVENTS_QUOTA
export CCTV_EVENTS_PATH

export CCTV_SEGMENTS_QUOTA
export CCTV_SEGMENTS_PATH
export CCTV_SEGMENT_DURATION

export CCTV_MOTION_CONFIGS

export DISABLE_NVIDIA

docker-compose up -d

docker-compose logs -f -t
