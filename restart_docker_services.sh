#!/bin/bash
if [[ "$1" == "all" ]]; then
    for dir in /srv/*; do
        [ -f "$dir/docker-compose.yaml" ] && docker compose -f "$dir/docker-compose.yaml" up -d
    done
else
    for dir in "$@"; do
        docker compose -f "$dir/docker-compose.yaml" up -d
    done
fi
