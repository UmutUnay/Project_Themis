#!/bin/sh
set -e

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
bin_dir="$repo_root/bin"
debian_dir="$repo_root/debian"
service_file="$debian_dir/themis.service"
package_dir="${THEMIS_DEB_BUILD_DIR:-$repo_root/build/debian/themis}"
source_parent="$package_dir/source"
debmake_log="$package_dir/debmake.log"

config_value() {
	key="$1"
	awk -F= -v key="$key" '$1 == key { gsub(/"/, "", $2); print $2; exit }' "$repo_root/build.conf"
}

deb_arch_for_themis_arch() {
	case "$1" in
		ARM)
			echo "arm64"
			;;
		x86)
			echo "amd64"
			;;
		*)
			echo "$1"
			;;
	esac
}

if [ ! -f "$service_file" ]; then
	echo "Missing service file: $service_file" >&2
	exit 1
fi

version_major="$(config_value CONFIG_VERSION_MAJOR)"
version_minor="$(config_value CONFIG_VERSION_MINOR)"
version_patch="$(config_value CONFIG_VERSION_SHAME)"
themis_arch="$(config_value CONFIG_ARCH)"

if [ -z "$version_major" ] || [ -z "$version_minor" ] || [ -z "$version_patch" ]; then
	echo "Could not read Themis version from build.conf." >&2
	exit 1
fi

if [ -z "$themis_arch" ]; then
	echo "Could not read CONFIG_ARCH from build.conf." >&2
	exit 1
fi

upstream_version="$version_major.$version_minor.$version_patch"
debian_revision="${THEMIS_DEB_REVISION:-1}"
debian_version="$upstream_version-$debian_revision"
deb_arch="$(deb_arch_for_themis_arch "$themis_arch")"
source_root="$source_parent/themis-$upstream_version"
deb_path="$source_parent/themis_${debian_version}_${deb_arch}.deb"

for required_file in \
	"$debian_dir/control" \
	"$debian_dir/changelog.in" \
	"$debian_dir/rules" \
	"$debian_dir/themis.postinst" \
	"$debian_dir/themis.postrm" \
	"$debian_dir/themis.service" \
	"$debian_dir/themis.1" \
	"$debian_dir/themis.manpages" \
	"$debian_dir/themis.lintian-overrides" \
	"$debian_dir/copyright" \
	"$debian_dir/source/format"
do
	if [ ! -f "$required_file" ]; then
		echo "Missing Debian packaging file: $required_file" >&2
		exit 1
	fi
done

rm -rf "$source_parent"
mkdir -p "$source_root"

rsync -a \
	"$repo_root/CMakeLists.txt" \
	"$repo_root/build.conf" \
	"$repo_root/confgen.py" \
	"$repo_root/README.md" \
	"$repo_root/LICENSE" \
	"$repo_root/cmake" \
	"$repo_root/components" \
	"$repo_root/main" \
	"$source_root/"

echo "Generating Debian skeleton with debmake..."
if ! (
	cd "$source_root"
	debmake \
		-y \
		-t \
		-p themis \
		-u "$upstream_version" \
		-r "$debian_revision" \
		-b themis:bin \
		-e "umutunay.27@gmail.com" \
		-f "Umut Ünay"
	) > "$debmake_log" 2>&1
then
	echo "debmake failed. See log:" >&2
	echo "  $debmake_log" >&2
	exit 1
fi

find "$source_root/debian" -type f \( -name '*.ex' -o -name '*.EX' \) -delete
rm -f \
	"$source_root/debian/README.Debian" \
	"$source_root/debian/README.source" \
	"$source_root/debian/clean" \
	"$source_root/debian/dirs" \
	"$source_root/debian/gbp.conf" \
	"$source_root/debian/install" \
	"$source_root/debian/links" \
	"$source_root/debian/salsa-ci.yml" \
	"$source_root/debian/watch"
rm -rf \
	"$source_root/debian/patches" \
	"$source_root/debian/tests" \
	"$source_root/debian/upstream"

cp "$debian_dir/control" "$source_root/debian/control"
cp "$debian_dir/rules" "$source_root/debian/rules"
cp "$debian_dir/themis.service" "$source_root/debian/themis.service"
cp "$debian_dir/themis.postinst" "$source_root/debian/themis.postinst"
cp "$debian_dir/themis.postrm" "$source_root/debian/themis.postrm"
cp "$debian_dir/themis.1" "$source_root/debian/themis.1"
cp "$debian_dir/themis.manpages" "$source_root/debian/themis.manpages"
cp "$debian_dir/themis.lintian-overrides" "$source_root/debian/themis.lintian-overrides"
cp "$debian_dir/copyright" "$source_root/debian/copyright"
cp "$debian_dir/source/format" "$source_root/debian/source/format"
chmod 0755 "$source_root/debian/rules" "$source_root/debian/themis.postinst" "$source_root/debian/themis.postrm"

build_date="$(date -R)"
sed \
	-e "s/@DEBIAN_VERSION@/$debian_version/g" \
	-e "s/@ARCHITECTURE@/$deb_arch/g" \
	-e "s/@DATE@/$build_date/g" \
	"$debian_dir/changelog.in" > "$source_root/debian/changelog"

echo "Building Debian package with debmake-generated source tree:"
echo "  source: $source_root"
echo "  arch:   $deb_arch"
echo "  cmake:  $source_root/CMakeLists.txt"

(
	cd "$source_root"
	dpkg-buildpackage -us -uc -b -a"$deb_arch"
)

last_deb_name="$(basename -- "$deb_path")"
bin_debian_dir="$bin_dir/debian"
mkdir -p "$bin_debian_dir"
cp "$deb_path" "$bin_debian_dir/$last_deb_name"
echo "Copied latest Debian package to:"
echo "  $bin_debian_dir/$last_deb_name"
