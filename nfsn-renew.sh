#!/usr/bin/env bash
readonly Dir="$(dirname "$0")"
readonly RealDir="$(realpath "${Dir}")"
dehydrated="${RealDir}/dehydrated/dehydrated"
"${dehydrated}" --cron
"${dehydrated}" --cleanup
