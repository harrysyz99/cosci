#!/bin/sh
# Installs the latest cosci release for x86_64 Linux or macOS.
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
  Linux-x86_64) platform="x86_64-linux"; sha256="sha256sum" ;;
  Darwin-arm64) platform="aarch64-macos"; sha256="shasum -a 256" ;;
  Darwin-x86_64) platform="x86_64-macos"; sha256="shasum -a 256" ;;
  *)
    echo "cosci supports x86_64 Linux and macOS (this machine: $(uname -s) $(uname -m))." >&2
    echo "On Windows, run: irm https://raw.githubusercontent.com/$repo/main/install.ps1 | iex" >&2
    exit 1
    ;;
esac

for tool in curl tar ${sha256%% *}; do
  command -v "$tool" >/dev/null 2>&1 || { echo "The cosci installer needs '$tool'." >&2; exit 1; }
done

# Follow the releases/latest redirect instead of calling the GitHub API, whose
# anonymous rate limit is easy to hit from shared campus or office networks.
latest=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")
tag=${latest##*/}
case "$tag" in
  cosci-*) ;;
  *)
    echo "Could not find the latest cosci release at https://github.com/$repo/releases." >&2
    exit 1
    ;;
esac
version=$(printf '%s' "${tag#cosci-}" | tr -d .)
url="https://github.com/$repo/releases/download/$tag/cosci-$version-$platform.tar.gz"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM
archive_name=$(basename "$url")
echo "Downloading $archive_name"
if ! curl -fL --progress-bar "$url" -o "$tmp/$archive_name"; then
  echo "Release $tag has no package for $platform." >&2
  exit 1
fi
curl -fsSL "$url.sha256" -o "$tmp/$archive_name.sha256"
if ! (cd "$tmp" && $sha256 -c "$archive_name.sha256" >/dev/null 2>&1); then
  echo "Checksum verification failed; nothing was installed." >&2
  exit 1
fi

tar -xzf "$tmp/$archive_name" -C "$tmp"
package=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d -name 'cosci-*' | head -n 1)

mkdir -p "$install_dir" "$bin_dir"
cp "$package/cosci" "$install_dir/cosci.new"
mv "$install_dir/cosci.new" "$install_dir/cosci"
# Linux packages carry the bubblewrap sandbox; macOS uses the system sandbox.
if [ -d "$package/codex-resources" ]; then
  cp -R "$package/codex-resources" "$install_dir/"
fi
ln -sf "$install_dir/cosci" "$bin_dir/cosci"

echo "Installed $("$install_dir/cosci" --version) in $install_dir"
profile="$HOME/.bashrc"
[ "$(uname -s)" = Darwin ] && profile="$HOME/.zshrc"
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) echo "Add $bin_dir to your PATH, for example: echo 'export PATH=\"$bin_dir:\$PATH\"' >> $profile" ;;
esac
echo "Next: cosci login   (over SSH: cosci login --device-auth)"
echo "cosci mirrors conversations to the cosci lab WebDAV server. To turn this off, add"
echo "  [transcript_cloud]"
echo "  provider = \"off\""
echo "to ~/.cosci/config.toml."
