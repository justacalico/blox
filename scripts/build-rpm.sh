#!/usr/bin/env bash
# Package a built Flutter Linux bundle as an RPM for Fedora and friends.
# Installs to /opt/blox with a /usr/bin/blox symlink, a desktop entry and
# an icon, matching the layout used by the .deb package built in CI.
#
# Usage: scripts/build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]
#   rpm-arch: x86_64 or aarch64
#   release: rpm release number, defaults to 1 (CI passes the build number so
#            nightly rpms stay upgradeable via dnf)
set -euo pipefail

BUNDLE_DIR="${1:?usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]}"
VERSION="${2:?usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]}"
ARCH="${3:?usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]}"
OUT="${4:?usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]}"
RELEASE="${5:-1}"

if ! command -v rpmbuild >/dev/null 2>&1; then
  echo "build-rpm: rpmbuild not found (install the rpm/rpm-build package)" >&2
  exit 1
fi
if [ ! -d "$BUNDLE_DIR" ]; then
  echo "build-rpm: bundle dir not found: $BUNDLE_DIR" >&2
  exit 1
fi
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
  echo "build-rpm: unsupported arch: $ARCH" >&2
  exit 1
fi

# rpm forbids '-' in Version; '~' is the rpm convention for prereleases and
# sorts before the final release.
RPM_VERSION="$(printf '%s' "$VERSION" | tr '-' '~')"

TOPDIR="$(mktemp -d)"
trap 'rm -rf "$TOPDIR"' EXIT
mkdir -p "$TOPDIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

cat > "$TOPDIR/SPECS/blox.spec" <<'EOF'
Name: blox
Version: %{pkg_version}
Release: %{pkg_release}%{?dist}
Summary: TI-84 Plus CE style graphing calculator
License: AGPL-3.0-only
URL: https://gitlab.com/HttpAnimations/blox

# The bundle is already compiled; skip debug packages and buildroot policy
# scripts (strip, rpath checks) that would mangle or reject the prebuilt libs.
%global debug_package %{nil}
%global __os_install_post %{nil}
# Bundled libs must not leak into the rpm provides namespace.
%global __provides_exclude_from ^/opt/blox/.*

%description
A TI-84 Plus CE style graphing calculator built with Flutter. Reproduces the
feel of the physical handheld with a skeuomorphic interface and supports
graphing, statistics, matrices, lists, programs and finance tools.

%install
mkdir -p %{buildroot}/opt/blox %{buildroot}/usr/bin \
  %{buildroot}/usr/share/applications \
  %{buildroot}/usr/share/icons/hicolor/256x256/apps
cp -a %{bundle_dir}/. %{buildroot}/opt/blox/
ln -sf /opt/blox/blox %{buildroot}/usr/bin/blox
install -m 644 %{bundle_dir}/data/flutter_assets/assets/icons/icon.png \
  %{buildroot}/usr/share/icons/hicolor/256x256/apps/blox.png
cat > %{buildroot}/usr/share/applications/blox.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Blox
Comment=TI-84 Plus CE style graphing calculator
Exec=/usr/bin/blox
Icon=blox
Categories=Utility;Science;Math;
Terminal=false
DESKTOP

%files
/opt/blox
/usr/bin/blox
/usr/share/applications/blox.desktop
/usr/share/icons/hicolor/256x256/apps/blox.png
EOF

rpmbuild -bb \
  --target "$ARCH" \
  --define "_topdir $TOPDIR" \
  --define "pkg_version $RPM_VERSION" \
  --define "pkg_release $RELEASE" \
  --define "bundle_dir $(realpath "$BUNDLE_DIR")" \
  "$TOPDIR/SPECS/blox.spec"

RPM_PATH="$(find "$TOPDIR/RPMS" -name '*.rpm' -print -quit)"
if [ -z "$RPM_PATH" ]; then
  echo "build-rpm: rpmbuild produced no rpm" >&2
  exit 1
fi
cp "$RPM_PATH" "$OUT"
echo "build-rpm: $RPM_PATH -> $OUT"
