#!/bin/sh
# Builds a Debian binary package for the zim-to-markdown executable.
set -eu

if [ "$#" -ne 3 ]; then
    echo "usage: $0 VERSION BINARY OUTPUT" >&2
    exit 2
fi

version="$1"
binary="$2"
output="$3"

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT

install -Dm755 "$binary" "$root/usr/bin/zim-to-markdown"
install -Dm644 README.md "$root/usr/share/doc/zim-to-markdown/README.md"
install -Dm644 CHANGELOG.md "$root/usr/share/doc/zim-to-markdown/CHANGELOG.md"
install -Dm644 LICENSE "$root/usr/share/doc/zim-to-markdown/copyright"
gzip -9 -n -c CHANGELOG.md > "$root/usr/share/doc/zim-to-markdown/changelog.gz"
chmod 644 "$root/usr/share/doc/zim-to-markdown/changelog.gz"
mkdir -p "$root/usr/share/man/man1"
sed "s|@VERSION@|$version|" packaging/zim-to-markdown.1 > "$root/usr/share/man/man1/zim-to-markdown.1"
chmod 644 "$root/usr/share/man/man1/zim-to-markdown.1"
gzip -9 -n "$root/usr/share/man/man1/zim-to-markdown.1"

strip --strip-unneeded "$root/usr/bin/zim-to-markdown"

installed_size="$(du -sk "$root" | cut -f1)"

mkdir -p "$root/DEBIAN"
cat > "$root/DEBIAN/control" <<EOF
Package: zim-to-markdown
Version: $version
Section: text
Priority: optional
Architecture: amd64
Depends: libc6 (>= 2.35), libgmp10
Installed-Size: $installed_size
Maintainer: Tralen <dev@tralen.cc>
Homepage: https://github.com/Tralen/zim-to-markdown
Description: Converts Zim wiki pages to Markdown and back
 A command line converter between Zim wiki markup and Markdown.
 It converts single pages and whole notebooks in both directions,
 copies notebook assets, preserves the folder structure, and resolves
 internal links.
 .
 Zim metadata headers are removed and heading levels are normalized
 for Markdown output.
EOF

chmod 755 "$root" "$root/usr" "$root/usr/bin" "$root/usr/share" \
    "$root/usr/share/doc" "$root/usr/share/doc/zim-to-markdown" \
    "$root/usr/share/man" "$root/usr/share/man/man1" "$root/DEBIAN"
chmod 644 "$root/DEBIAN/control"

mkdir -p "$(dirname "$output")"
dpkg-deb --build --root-owner-group "$root" "$output"
