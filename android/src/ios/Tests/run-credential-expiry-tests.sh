#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT
swiftc "$root/Morde/MordeCredentialExpiry.swift" "$root/Tests/MordeCredentialExpiryTests.swift" -o "$temp/morde-credential-expiry-tests"
"$temp/morde-credential-expiry-tests"
