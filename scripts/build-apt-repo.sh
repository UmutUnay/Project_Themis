#!/bin/sh
set -e

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
deb_dir="${THEMIS_DEB_DIR:-$repo_root/bin/debian}"
apt_repo="${THEMIS_APT_REPO_DIR:-$repo_root/bin/apt}"
dist="${THEMIS_APT_DIST:-stable}"
component="${THEMIS_APT_COMPONENT:-main}"
origin="${THEMIS_APT_ORIGIN:-Project Themis}"
label="${THEMIS_APT_LABEL:-Project Themis}"
base_url="${THEMIS_APT_BASE_URL:-}"
signing_key="${THEMIS_APT_SIGNING_KEY:-}"

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Missing required command: $1" >&2
		exit 1
	fi
}

add_architecture() {
	arch_to_add="$1"

	for existing_arch in $architectures; do
		if [ "$existing_arch" = "$arch_to_add" ]; then
			return
		fi
	done

	architectures="${architectures}${architectures:+ }$arch_to_add"
}

comma_architectures() {
	first=1
	for arch in $architectures; do
		if [ "$first" -eq 1 ]; then
			printf "%s" "$arch"
			first=0
		else
			printf ",%s" "$arch"
		fi
	done
}

require_command apt-ftparchive
require_command dpkg-deb
require_command dpkg-scanpackages
require_command gzip

if [ ! -d "$deb_dir" ]; then
	echo "Missing Debian package directory: $deb_dir" >&2
	echo "Run ./scripts/deb_service_gen.sh first." >&2
	exit 1
fi

pool_dir="$apt_repo/pool/$component/t/themis"
dist_dir="$apt_repo/dists/$dist"
mkdir -p "$pool_dir" "$dist_dir"

architectures=""
packages_found=0

for deb in "$deb_dir"/themis_*.deb; do
	if [ ! -f "$deb" ]; then
		continue
	fi

	package_name="$(dpkg-deb -f "$deb" Package)"
	if [ "$package_name" != "themis" ]; then
		continue
	fi

	package_arch="$(dpkg-deb -f "$deb" Architecture)"
	if [ -z "$package_arch" ]; then
		echo "Could not read package architecture: $deb" >&2
		exit 1
	fi

	cp "$deb" "$pool_dir/"
	add_architecture "$package_arch"
	packages_found=$((packages_found + 1))
done

if [ "$packages_found" -eq 0 ]; then
	echo "No themis .deb packages found in: $deb_dir" >&2
	echo "Run ./scripts/deb_service_gen.sh first." >&2
	exit 1
fi

(
	cd "$apt_repo"

	for arch in $architectures; do
		binary_dir="dists/$dist/$component/binary-$arch"
		mkdir -p "$binary_dir"
		dpkg-scanpackages --arch "$arch" "pool/$component" > "$binary_dir/Packages"
		gzip -9cn "$binary_dir/Packages" > "$binary_dir/Packages.gz"
	done

	apt-ftparchive \
		-o APT::FTPArchive::Release::Origin="$origin" \
		-o APT::FTPArchive::Release::Label="$label" \
		-o APT::FTPArchive::Release::Suite="$dist" \
		-o APT::FTPArchive::Release::Codename="$dist" \
		-o APT::FTPArchive::Release::Architectures="$architectures" \
		-o APT::FTPArchive::Release::Components="$component" \
		release "dists/$dist" > "dists/$dist/Release"
)

if [ -n "$signing_key" ]; then
	require_command gpg
	gpg --batch --yes --default-key "$signing_key" --clearsign \
		-o "$dist_dir/InRelease" "$dist_dir/Release"
	gpg --batch --yes --default-key "$signing_key" -abs \
		-o "$dist_dir/Release.gpg" "$dist_dir/Release"
	gpg --batch --yes --export "$signing_key" > "$apt_repo/project-themis-archive-keyring.gpg"
	signing_state="signed"
else
	signing_state="unsigned"
fi

echo "Built $signing_state APT repository:"
echo "  $apt_repo"
echo
echo "Repository contents to publish:"
echo "  $apt_repo/dists"
echo "  $apt_repo/pool"

if [ -n "$signing_key" ]; then
	echo "  $apt_repo/project-themis-archive-keyring.gpg"
else
	echo
	echo "Set THEMIS_APT_SIGNING_KEY to sign the repository before public release."
fi

if [ -n "$base_url" ]; then
	arch_list="$(comma_architectures)"
	echo
	echo "User install commands after publishing:"
	if [ -n "$signing_key" ]; then
		echo "  curl -fsSL $base_url/project-themis-archive-keyring.gpg | sudo tee /usr/share/keyrings/project-themis-archive-keyring.gpg >/dev/null"
		echo "  echo \"deb [arch=$arch_list signed-by=/usr/share/keyrings/project-themis-archive-keyring.gpg] $base_url $dist $component\" | sudo tee /etc/apt/sources.list.d/themis.list"
	else
		echo "  echo \"deb [arch=$arch_list trusted=yes] $base_url $dist $component\" | sudo tee /etc/apt/sources.list.d/themis.list"
	fi
	echo "  sudo apt update"
	echo "  sudo apt install themis"
fi
