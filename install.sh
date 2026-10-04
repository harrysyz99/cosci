#!/bin/sh
# Installs the latest cosci release for x86_64 Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/harrysyz99/cosci/main/install.sh | sh
#
# COSCI_INSTALL_DIR (default ~/.local/lib/cosci) holds the program and its
# sandbox helper; COSCI_BIN_DIR (default ~/.local/bin) gets a `cosci` link.
set -eu

repo="harrysyz99/cosci"
install_dir="${COSCI_INSTALL_DIR:-$HOME/.local/lib/cosci}"
bin_dir="${COSCI_BIN_DIR:-$HOME/.local/bin}"

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) ;;
  *)
    echo "cosci currently supports x86_64 Linux only (this machine: $(uname -s) $(uname -m))." >&2
    exit 1
    ;;
esac

for tool in curl tar sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || { echo "The cosci installer needs '$tool'." >&2; exit 1; }
done

url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
  | grep -o '"browser_download_url": *"[^"]*x86_64-linux\.tar\.gz"' \
  | head -n 1 \
  | sed 's/.*"\(https[^"]*\)"$/\1/')
if [ -z "$url" ]; then
  echo "Could not find a cosci release for x86_64 Linux at https://github.com/$repo/releases." >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM
archive_name=$(basename "$url")
echo "Downloading $archive_name"
curl -fL --progress-bar "$url" -o "$tmp/$archive_name"
curl -fsSL "$url.sha256" -o "$tmp/$archive_name.sha256"
if ! (cd "$tmp" && sha256sum -c "$archive_name.sha256" >/dev/null 2>&1); then
  echo "Checksum verification failed; nothing was installed." >&2
  exit 1
fi

tar -xzf "$tmp/$archive_name" -C "$tmp"
package=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d -name 'cosci-*' | head -n 1)

mkdir -p "$install_dir" "$bin_dir"
cp "$package/cosci" "$install_dir/cosci.new"
mv "$install_dir/cosci.new" "$install_dir/cosci"
cp -R "$package/codex-resources" "$install_dir/"
ln -sf "$install_dir/cosci" "$bin_dir/cosci"

echo "Installed $("$install_dir/cosci" --version) in $install_dir"
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) echo "Add $bin_dir to your PATH, for example: echo 'export PATH=\"$bin_dir:\$PATH\"' >> ~/.bashrc" ;;
esac
echo "Next: cosci login   (over SSH: cosci login --device-auth)"
