#!/usr/bin/env bash
# Test, package and publish Flint Swarm to Open VSX, the registry behind Cursor's Extensions
# panel. Publishing needs an Open VSX access token for the dodellsoftwareservices namespace
# (open-vsx.org → your avatar → Settings → Access Tokens):
#
#   OVSX_PAT=... ./cursor-extension/publish.sh       # test, package, publish
#   ./cursor-extension/publish.sh --package-only     # build flint-swarm-<version>.vsix only
#
# Bump "version" in package.json before each publish; a registry never takes the same one twice.
set -euo pipefail
cd "$(dirname "$0")"
# install.sh writes this machine's checkout path into flint-root.txt for a local install. A
# published package must not carry it: store installs find Flint through Install Flint… instead.
rm -f flint-root.txt
node test/extension.test.js
version="$(node -p "require('./package.json').version")"
out="flint-swarm-$version.vsix"
npx --yes @vscode/vsce@3 package --out "$out"
if unzip -l "$out" | grep -q "flint-root.txt"; then
  echo "refusing to publish: $out contains flint-root.txt" >&2
  exit 1
fi
if [ "${1:-}" = "--package-only" ]; then
  echo "packaged $out"
  exit 0
fi
: "${OVSX_PAT:?set OVSX_PAT to an Open VSX access token for the dodellsoftwareservices namespace}"
npx --yes ovsx@0 publish "$out" -p "$OVSX_PAT"
echo "published $out to Open VSX; it shows up in Cursor's Extensions panel once the registry syncs"
