#!/usr/bin/env bash
# Installs myfetch.sh as the "neofetch" command.
# On dpkg systems (Termux, Debian, Ubuntu) it registers a package named
# "neofetch", so "pkg install neofetch" / "apt install neofetch" report it
# as already installed.
#
# Install:  bash install-myfetch.sh
# Remove:   bash install-myfetch.sh remove

set -e
umask 022   # dpkg-deb needs 755 directories (Termux default umask is 077)

HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$HERE/myfetch.sh"
PKG=neofetch
VER=99.0.0

# Termux does not use root/sudo
SUDO=""
if [[ "$PREFIX" == *com.termux* ]]; then
  BIN="$PREFIX/bin"
else
  BIN="/usr/bin"
  if [ "$(id -u)" != "0" ]; then
    if command -v sudo >/dev/null 2>&1; then
      SUDO="sudo"
    else
      echo "Run as root or install sudo."
      exit 1
    fi
  fi
fi

# ---------- remove ----------
if [ "$1" = "remove" ]; then
  if command -v dpkg >/dev/null 2>&1 && dpkg -s "$PKG" >/dev/null 2>&1; then
    $SUDO dpkg -r "$PKG"
  else
    $SUDO rm -f "$BIN/neofetch" /usr/local/bin/neofetch
  fi
  hash -r 2>/dev/null || true
  echo "Removed."
  exit 0
fi

# ---------- install ----------
if [ ! -f "$SRC" ]; then
  echo "myfetch.sh not found next to this installer ($HERE)."
  exit 1
fi

# No dpkg (Arch, Fedora...): plain copy
if ! command -v dpkg-deb >/dev/null 2>&1; then
  DEST=/usr/local/bin
  [ -n "$SUDO" ] || [ "$(id -u)" = "0" ] || SUDO="sudo"
  $SUDO install -m 755 "$SRC" "$DEST/neofetch"
  hash -r 2>/dev/null || true
  echo "Installed to $DEST/neofetch. Type: neofetch"
  exit 0
fi

# dpkg systems: build and install a small package
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/pkg/DEBIAN" "$TMP/pkg$BIN"

# make the shebang point at this system's bash (Termux has no /bin/bash)
BASH_PATH=$(command -v bash)
{ echo "#!$BASH_PATH"; tail -n +2 "$SRC"; } > "$TMP/pkg$BIN/neofetch"
chmod 755 "$TMP/pkg$BIN/neofetch"
find "$TMP/pkg" -type d -exec chmod 755 {} +

cat > "$TMP/pkg/DEBIAN/control" <<EOF
Package: $PKG
Version: $VER
Architecture: all
Maintainer: local <local@localhost>
Depends: bash
Section: utils
Description: neofetch (custom myfetch build)
 Colorful system info tool.
EOF

DEB="$TMP/$PKG.deb"
dpkg-deb --root-owner-group --build "$TMP/pkg" "$DEB" >/dev/null 2>&1 \
  || dpkg-deb --build "$TMP/pkg" "$DEB" >/dev/null

$SUDO dpkg -i "$DEB"
hash -r 2>/dev/null || true

echo
echo "Done. Type: neofetch"
echo "Check:     pkg install neofetch   (shows: already the newest version)"
