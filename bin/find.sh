#!/usr/bin/env bash

find . \
  -not -path "*.virtualenv*" \
  -not -path "*node_modules*" \
  -not -path "*.git*" \
  -not -path "*.terraform*" \
  $@
