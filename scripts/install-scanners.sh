#!/usr/bin/env bash
# Install pinned security scanners into $HOME/.local/bin, verifying every download
# against the publisher's checksum file. Scanners are installed directly rather than
# through third-party GitHub Actions, so a moved or compromised action tag cannot
# change what runs. Bump the versions deliberately (Renovate can propose bumps).
set -euo pipefail
GITLEAKS_VERSION="${GITLEAKS_VERSION:-8.30.1}"
OSV_VERSION="${OSV_VERSION:-2.7.0}"
TRIVY_VERSION="${TRIVY_VERSION:-0.76.1}"
SEMGREP_VERSION="${SEMGREP_VERSION:-1.182.1}"
bin="$HOME/.local/bin"; mkdir -p "$bin"; tmp="$(mktemp -d)"; cd "$tmp"

fetch() { curl -sSfL --retry 3 -o "$2" "$1"; }
verify() { # verify <file> <checksums-file>
  grep -E "[[:space:]]\*?$1\$" "$2" | sha256sum -c - >/dev/null \
    || { echo "checksum mismatch for $1" >&2; exit 1; }
}

gl="gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
fetch "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/$gl" "$gl"
fetch "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_checksums.txt" gl.sums
verify "$gl" gl.sums; tar -xzf "$gl" gitleaks; install -m 0755 gitleaks "$bin/"

osv="osv-scanner_linux_amd64"
fetch "https://github.com/google/osv-scanner/releases/download/v${OSV_VERSION}/$osv" "$osv"
fetch "https://github.com/google/osv-scanner/releases/download/v${OSV_VERSION}/osv-scanner_SHA256SUMS" osv.sums
verify "$osv" osv.sums; install -m 0755 "$osv" "$bin/osv-scanner"

tv="trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz"
fetch "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/$tv" "$tv"
fetch "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_checksums.txt" tv.sums
verify "$tv" tv.sums; tar -xzf "$tv" trivy; install -m 0755 trivy "$bin/"

python3 -m pip install --quiet --user "semgrep==${SEMGREP_VERSION}"

[ -n "${GITHUB_PATH:-}" ] && echo "$bin" >> "$GITHUB_PATH"
export PATH="$bin:$PATH"
gitleaks version; osv-scanner --version | head -1; trivy --version | head -1; semgrep --version
