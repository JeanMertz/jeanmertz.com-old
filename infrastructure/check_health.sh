#!/bin/sh

curl \
    --silent \
    --retry 600 \
    --retry-delay 1 \
    --retry-max-time 600 \
    --max-time 0.2 \
    "http://$1/health"
