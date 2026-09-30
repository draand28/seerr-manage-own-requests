#!/usr/bin/env bash
# Install the "Manage Own Requests" patch into a Seerr source checkout.
#
#   ./install.sh [seerr-dir]
#
# seerr-dir defaults to ./seerr and is cloned if missing. Override the pinned
# upstream commit with SEERR_REF=... if you are rebasing onto a newer Seerr.
set -euo pipefail

SEERR_REPO="${SEERR_REPO:-https://github.com/seerr-team/seerr.git}"
SEERR_REF="${SEERR_REF:-e2f24cb46079746936516c723b09820360f95113}"
SEERR_DIR="${1:-seerr}"
PATCH_DIR="$(cd "$(dirname "$0")" && pwd)/patches"

if [ ! -d "$SEERR_DIR/.git" ]; then
  echo "==> Initializing Seerr checkout in $SEERR_DIR"
  git init -q "$SEERR_DIR"
  git -C "$SEERR_DIR" remote add origin "$SEERR_REPO"
fi

echo "==> Checking out $SEERR_REF"
git -C "$SEERR_DIR" fetch --depth 1 origin "$SEERR_REF"
git -C "$SEERR_DIR" checkout --detach -f FETCH_HEAD

for patch in "$PATCH_DIR"/*.patch; do
  echo "==> Applying $(basename "$patch")"
  git -C "$SEERR_DIR" apply "$patch"
done

echo "==> Installing dependencies and building"
command -v pnpm >/dev/null 2>&1 || corepack enable
(cd "$SEERR_DIR" && pnpm install --frozen-lockfile && pnpm build)

cat <<EOF

Done. Start Seerr with:
  cd $SEERR_DIR && pnpm start

Then grant "Manage Own Requests" under Settings > Users > Permissions.
EOF
