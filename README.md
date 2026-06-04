# Project Themis

Project Themis is a Linux service management project built around a C++ server, D-Bus communication, an HTTP API, service plugins, a Dart CLI/TUI, and a Flutter GUI. It is designed to supervise and configure system services through small service-specific plugins instead of hard-coding every service into the main server.

The project started as a METU CEng graduation project and is being prepared as an open-source Linux tool.

## What It Does

- Runs a Themis server that exposes local HTTP endpoints for service/plugin management.
- Uses D-Bus to communicate between the server, plugins, systemd, and service-specific handlers.
- Loads plugins from Themis metadata under `/etc/themis/plugins`.
- Provides plugin UI schemas through JSON so the GUI and CLI can render service configuration screens.
- Includes Dart and Flutter clients for terminal and graphical management workflows.
- Contains Debian packaging and APT repository scripts for Linux distribution.

## Who We Are

| Name | Role | Contributions |
| --- | --- | --- |
| Onur Tolga Şehitoğlu | Advisor | Supervised and advised the project. |
| Umut Ünay | Lead Developer | Developed the main Themis server, core components, Firewalld plugin, Example plugin, APT packaging, and project information website. |
| Emre Kaan Kaçan | Developer | Developed the Apache plugin. |
| Tuna Demirdöğen | Developer | Developed the Themis GUI and Themis CLI. |
| Yiğit Alp Alakoç | Developer | Developed the remote access tool and remote access plugin. |

## Repository Layout

| Path | Purpose |
| --- | --- |
| `main` | Themis server entrypoint, startup flow, HTTP route registration, plugin restore logic. |
| `components` | Reusable C++ components for D-Bus, HTTP, threading, and shared definitions. |
| `plugins` | Service plugins, including example, firewalld, Apache, and remote access tool work. |
| `themis_ui_lib` | Shared Dart client, models, plugin config data, and UI schema parsing. |
| `themis_cli` | Dart command-line interface and terminal UI. |
| `themis_gui` | Flutter/Yaru graphical interface. |
| `cmake` | Custom CMake helpers for Themis components, config generation, and target selection. |
| `debian` | Debian package metadata and systemd service files. |
| `scripts` | Debian package and APT repository generation scripts. |
| `templates` | D-Bus policy template files. |
| `Documents` | Development notes, contribution guide, and issue templates. |

## Requirements

Core server and plugin development:

- Linux with D-Bus and systemd.
- CMake 3.16 or newer.
- Python 3.
- `pkg-config`.
- `libdbus-1-dev`.
- GCC/G++ for x86 builds, or `aarch64-linux-gnu-gcc` and `aarch64-linux-gnu-g++` for ARM builds.
- Network access during the first CMake configure, because CMake FetchContent downloads external C++ dependencies.

CLI and GUI development:

- Dart SDK for `themis_cli` and `themis_ui_lib`.
- Flutter SDK for `themis_gui`.

Packaging:

- Debian packaging tools such as `debmake`, `dpkg-buildpackage`, `dpkg-deb`, `dpkg-scanpackages`, `apt-ftparchive`, `rsync`, `gzip`, and optionally `gpg`.

Additional editor recommendations are listed in [`Documents/RequirementsForDevelopment.md`](Documents/RequirementsForDevelopment.md).

## Build Configuration

The C++ build is controlled by [`build.conf`](build.conf). Important values include:

- `CONFIG_PROJECT_NAME`: output project/binary name.
- `CONFIG_VERSION_MAJOR`, `CONFIG_VERSION_MINOR`, `CONFIG_VERSION_SHAME`: generated version.
- `CONFIG_ARCH`: selects compiler and output architecture. Use `x86` for local x86 development or `ARM` for aarch64 cross builds.
- `CONFIG_THEMIS_IPV4` and `CONFIG_THEMIS_PORT`: server bind address and HTTP port.

The current root config defaults to x86. For local ARM development, set:

```conf
# CONFIG_ARCH="x86"
CONFIG_ARCH="ARM"
```

Build outputs are copied to:

```text
bin/<project-name>_<architecture>_v<major>.<minor>.<patch>
```

For example:

```text
bin/Themis_Server_x86_v0.1.4
bin/Themis_Server_ARM_v0.1.4
```

## Build From Source

Build the main Themis server:

```sh
cmake -S . -B build -D_TARGET_NAME=main
cmake --build build
```

Build a plugin by passing the plugin directory name as `_TARGET_NAME`:

```sh
cmake -S . -B build-firewalld -D_TARGET_NAME=firewalld
cmake --build build-firewalld

cmake -S . -B build-example -D_TARGET_NAME=example
cmake --build build-example

cmake -S . -B build-rat -D_TARGET_NAME=remote_access_tool_plugin
cmake --build build-rat
```

The remote access tool also contains a separate client agent target:

```sh
cmake -S plugins/remote_access_tool_plugin/client_agent -B build-client-agent
cmake --build build-client-agent
```

## Runtime Notes

The server expects Linux system integration paths such as:

- `/etc/themis/plugins`
- `/etc/themis/rules`
- `/etc/themis/gui/run_web`

It registers the D-Bus name:

```text
org.themis.ProjectThemis
```

For manual development runs, build the server and run the generated binary from `bin`. Depending on your D-Bus/systemd setup and the files under `/etc/themis`, this may require elevated permissions.

## HTTP API

By default, the server binds to:

```text
http://127.0.0.1:5000
```

Registered routes include:

| Method | Route | Purpose |
| --- | --- | --- |
| `GET` | `/themis/plugins` | List installed plugin briefs. |
| `GET` | `/themis/plugins/:plugin_id/ui` | Read a plugin UI schema. |
| `GET` | `/themis/plugins/:plugin_id/test` | Send a test message to a plugin. |
| `PUT` | `/themis/plugins/:plugin_id/restart` | Restart the system service managed by a plugin. |
| `GET` | `/themis/plugins/:plugin_id/config` | List config types/files for a plugin. |
| `GET` | `/themis/plugins/:plugin_id/config/:conf_id` | Read one plugin config file. |
| `POST` | `/themis/plugins/:plugin_id/config/:conf_id` | Write one plugin config file. |
| `PUT` | `/themis/plugins/:plugin_id/config/:conf_id` | Generate a new plugin config file. |
| `DELETE` | `/themis/plugins/:plugin_id/config/:conf_id` | Remove one plugin config file. |
| `POST` | `/themis/plugins/local_install` | Install a local plugin binary already present on the server. |

## CLI

Install dependencies and run the CLI from `themis_cli`:

```sh
cd themis_cli
dart pub get
dart run bin/themis_cli.dart --server http://127.0.0.1:5000 list_plugins
```

Useful commands include:

- `list_plugins`
- `list_files`
- `read`
- `print`
- `get`
- `set`
- `write`
- `create`
- `delete`
- `restart`
- `test`
- `install_local`
- `tui`

Use the CLI help output for command-specific arguments:

```sh
dart run bin/themis_cli.dart --help
dart run bin/themis_cli.dart <command> --help
```

For local UI/client development without a real server, some flows support the hidden `--dev` test client.

## GUI

Install dependencies and run the Flutter GUI from `themis_gui`:

```sh
cd themis_gui
flutter pub get
flutter run -d linux
```

The GUI uses the shared Dart client models from `themis_ui_lib`, Yaru widgets, and the plugin `ui.json` schema exposed by the Themis server.

## Shared UI Library

The shared Dart package contains:

- The HTTP Themis client.
- Plugin and config data models.
- Plugin UI item models.
- Demo/test client support for CLI and GUI development.

Run its tests with:

```sh
cd themis_ui_lib
dart pub get
dart test
```

## Plugins

Plugins are built as separate CMake targets under `plugins`. A plugin typically provides:

- A C++ executable.
- A `build.conf` override.
- D-Bus rules/credentials used by the server.
- A `ui.json` file consumed by the CLI and GUI.
- Service-specific config read/write/generate handlers.

Current plugin directories:

- `plugins/example`
- `plugins/firewalld`
- `plugins/apache`
- `plugins/remote_access_tool_plugin`

Installed plugin metadata is expected under `/etc/themis/plugins`.

## Packaging

Build a Debian package:

```sh
./scripts/deb_service_gen.sh
```

The generated package is copied to:

```text
bin/debian/
```

Build a local APT repository from generated packages:

```sh
./scripts/build-apt-repo.sh
```

Optional environment variables:

- `THEMIS_DEB_BUILD_DIR`
- `THEMIS_DEB_REVISION`
- `THEMIS_DEB_DIR`
- `THEMIS_APT_REPO_DIR`
- `THEMIS_APT_DIST`
- `THEMIS_APT_COMPONENT`
- `THEMIS_APT_BASE_URL`
- `THEMIS_APT_SIGNING_KEY`

## Testing

Run the available Dart/Flutter tests:

```sh
cd themis_ui_lib && dart test
cd ../themis_cli && dart test
cd ../themis_gui && flutter test
```

For C++ changes, at minimum build the affected CMake target. Plugin and server behavior should also be checked manually against D-Bus, systemd, and the relevant HTTP endpoint when possible.

## Documentation

Project documents:

- [`Documents/HowToContribute.md`](Documents/HowToContribute.md): contribution workflow, review expectations, setup notes, and testing guidance.
- [`Documents/RequirementsForDevelopment.md`](Documents/RequirementsForDevelopment.md): editor/tooling requirements used during development.
- [`Documents/FormattingRules.md`](Documents/FormattingRules.md): coding and commit-message conventions.
- [`CREDITS`](CREDITS): external projects, libraries, assets, and tools used by Themis.
- [`LICENSE`](LICENSE): Project Themis license text.

Issue templates live in `Documents`:

- [`Documents/BugReportTemplate.md`](Documents/BugReportTemplate.md)
- [`Documents/GenericIssueTemplate.md`](Documents/GenericIssueTemplate.md)
- [`Documents/RequestTemplate.md`](Documents/RequestTemplate.md)

## License

Project Themis is licensed under the GNU General Public License v3.0. See [`LICENSE`](LICENSE).

We chose GPLv3 because Themis is a practical Linux system-service tool. Users who install it should keep the freedom to inspect, modify, rebuild, and redistribute the service manager that can affect their local machine and system configuration. GPLv3 also gives stronger protection against patent retaliation and device restrictions than older GPL versions, while remaining compatible with the permissive and weak-copyleft dependencies currently used by the project.

This is the current GPLv3 compatibility summary for the direct external projects listed in [`CREDITS`](CREDITS):

| External area | Examples in Themis | License family | GPLv3 status | Notes |
| --- | --- | --- | --- | --- |
| Permissive C++ libraries | `cpp-httplib`, `nlohmann/json` | MIT/Expat | Compatible | Preserve upstream copyright and license notices. |
| XML parsing | `tinyxml2` | zlib | Compatible | Keep the upstream notice. |
| System bus integration | `libdbus-1` | dual AFL/GPL family | Compatible path available | Use the GPL-compatible license option when distributing with Themis. |
| Dart and Flutter packages | `args`, `collection`, `dio`, `equatable`, `go_router`, `provider`, `window_manager`, `file_picker`, and others | mostly BSD-3-Clause, MIT/Expat, or Apache-2.0 | Compatible | Apache-2.0 is compatible with GPLv3, but not GPLv2; this is one reason GPLv3 is the safer GPL version here. |
| Yaru GUI package | `yaru` | MPL-2.0 for widgets/theme, CC-BY-SA-4.0 for icons, GPLv3 for scripts | Compatible with care | Keep notices. Treat icon assets as separately licensed artwork. |
| Bundled font | IBM Plex Mono | SIL Open Font License 1.1 | Fine for bundled fonts | Keep `themis_gui/assets/google_fonts/OFL.txt` with the font. |
| Build and packaging tools | CMake, Python, Debian tools | tool licenses vary | Does not normally affect Themis source license | Build tools do not relicense generated Themis source; still preserve notices when redistributing tool output that includes third-party material. |

The project can use GPLv3 as seen above table. The important release obligation is not changing Themis' license, but preserving third-party notices, keeping bundled license files, and making corresponding source available when distributing GPLv3-covered binaries.
