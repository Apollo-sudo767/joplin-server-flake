#!/usr/bin/env bash
set -euo pipefail

# Root directory of the repository
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=========================================================="
echo "  Joplin Server Flake - Automated Upstream & Lock Updater"
echo "=========================================================="

# 1. Determine current version in package.nix
CURRENT_VERSION=$(grep -E '^\s*version = "[^"]+"' package.nix | head -n1 | sed -E 's/.*version = "([^"]+)".*/\1/')
echo "Current version in package.nix: ${CURRENT_VERSION}"

# 2. Query Docker Hub for latest semantic version tag
echo "Checking Docker Hub for latest joplin/server release..."
LATEST_VERSION=$(curl -fsSL "https://hub.docker.com/v2/repositories/joplin/server/tags?page_size=50&ordering=last_updated" \
  | jq -r '.results[].name' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
  | head -n1 || true)

if [ -z "${LATEST_VERSION}" ]; then
  echo "Warning: Could not determine latest version from Docker Hub. Retaining current version (${CURRENT_VERSION})."
  LATEST_VERSION="${CURRENT_VERSION}"
fi

echo "Latest upstream version: ${LATEST_VERSION}"

if [ "${LATEST_VERSION}" != "${CURRENT_VERSION}" ]; then
  echo "New upstream version found: ${CURRENT_VERSION} -> ${LATEST_VERSION}"
  
  # Fetch amd64 digest from Docker Hub
  TAG_INFO=$(curl -fsSL "https://hub.docker.com/v2/repositories/joplin/server/tags/${LATEST_VERSION}")
  AMD64_DIGEST=$(echo "$TAG_INFO" | jq -r '.images[] | select(.architecture=="amd64") | .digest' | head -n1)
  
  if [ -z "${AMD64_DIGEST}" ] || [ "${AMD64_DIGEST}" = "null" ]; then
    echo "Error: Could not retrieve amd64 digest for joplin/server:${LATEST_VERSION}"
    exit 1
  fi
  echo "AMD64 digest: ${AMD64_DIGEST}"
  
  # Prefetch image sha256 using nix-prefetch-docker
  echo "Prefetching image layers using nix-prefetch-docker..."
  PREFETCH_JSON=$(nix-shell -p nix-prefetch-docker --run "nix-prefetch-docker --image-name joplin/server --image-digest '${AMD64_DIGEST}' --final-image-name joplin/server --final-image-tag '${LATEST_VERSION}' --json --quiet")
  
  NEW_SHA256=$(echo "${PREFETCH_JSON}" | jq -r '.hash')
  if [ -z "${NEW_SHA256}" ] || [ "${NEW_SHA256}" = "null" ]; then
    echo "Error: Failed to obtain sha256 from nix-prefetch-docker"
    exit 1
  fi
  echo "Calculated sha256: ${NEW_SHA256}"
  
  # Update package.nix, module.nix, and README.md using python3
  python3 - <<EOF
import re

# Update package.nix
with open("package.nix", "r") as f:
    pkg = f.read()

pkg = re.sub(r'version = "[^"]+";', f'version = "${LATEST_VERSION}";', pkg, count=1)
pkg = re.sub(r'imageDigest = "sha256:[^"]+";', f'imageDigest = "${AMD64_DIGEST}";', pkg, count=1)
pkg = re.sub(r'sha256 = "[^"]+";', f'sha256 = "${NEW_SHA256}";', pkg, count=1)

with open("package.nix", "w") as f:
    f.write(pkg)

# Update module.nix
with open("module.nix", "r") as f:
    mod = f.read()

mod = re.sub(r'default = "docker\.io/joplin/server:[^"]+";', f'default = "docker.io/joplin/server:${LATEST_VERSION}";', mod, count=1)

with open("module.nix", "w") as f:
    f.write(mod)

# Update README.md
with open("README.md", "r") as f:
    readme = f.read()

readme = re.sub(r'docker\.io/joplin/server:[0-9]+\.[0-9]+\.[0-9]+', f'docker.io/joplin/server:${LATEST_VERSION}', readme)

with open("README.md", "w") as f:
    f.write(readme)
EOF

  echo "Updated package.nix, module.nix, and README.md to ${LATEST_VERSION}."
else
  echo "Joplin Server package is up to date (${CURRENT_VERSION})."
fi

# 3. Update flake.lock inputs
echo "Updating flake inputs (nix flake update)..."
nix flake update

# 4. Verify flake configuration
echo "Verifying flake outputs (nix flake check)..."
nix flake check

echo "Flake update and verification completed successfully!"
