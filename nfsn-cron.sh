#!/usr/bin/env bash
readonly Dir="$(dirname "$0")"
readonly RealDir="$(realpath "${Dir}")"
cd "${RealDir}"
"${RealDir}/nfsn-renew.sh"
