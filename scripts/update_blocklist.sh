#!/bin/bash

set -e

tmpdir=$(mktemp -d)
curl -fL https://github.com/sqids/sqids-blocklist/raw/refs/heads/main/output/blocklist.json -o "$tmpdir"/blocklist.json

blocklist=$(cat "$tmpdir/blocklist.json")
blocklist=${blocklist:1:-1}

blfile=$(
cat <<HEREDOC
package sqids

@(rodata)
default_blocklist := [?]string{ $blocklist }
HEREDOC
)

echo "$blfile" > blocklist.odin
