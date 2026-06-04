# Contributing to Project Themis

Project Themis is a GPLv3 Linux service manager with a C++ server, D-Bus and HTTP communication, service plugins, a Dart CLI/TUI, a Flutter GUI, and Debian/APT packaging. Contributions are welcome when they keep the project understandable, reproducible, and safe for users who run it near system services.

## Project Areas

- `main` and `components`: C++23 server startup, HTTP API, D-Bus communication, threading, and shared helpers.
- `plugins`: service integrations such as firewalld, Apache, and the remote access tool plugin.
- `themis_ui_lib`: shared Dart models, client API, config data, and plugin UI parsing.
- `themis_cli`: command-line and terminal UI workflows.
- `themis_gui`: Flutter/Yaru desktop and web interface.
- `debian`, `scripts`, and `templates`: systemd service files, Debian package generation, APT repository generation, and D-Bus policy templates.
- `Documents`: contributor-facing docs, issue templates, and project requirements.

## Before You Start

- Search existing issues and pull requests before opening new work.
- Use the issue templates in `Documents` when reporting bugs, requesting features, or tracking general project work.
- Open an issue first for large design changes, D-Bus or HTTP API changes, plugin schema changes, packaging changes, and anything that touches privileged operations.
- Keep secrets out of issues, commits, logs, screenshots, and test data.
- Respect the GPLv3 license. Contributions are expected to be compatible with the repository license.

## Development Setup

Recommended tools are listed in `Documents/RequirementsForDevelopment.md`. In practice, contributors usually need:

- Linux for full server, D-Bus, systemd, and plugin testing.
- CMake 3.16 or newer, Python 3, and a C++23 compiler.
- GCC/G++ for x86 builds or the aarch64 cross compiler for ARM builds.
- Dart SDK for `themis_cli` and `themis_ui_lib`.
- Flutter SDK for `themis_gui`.
- Debian packaging tools only when working on `.deb` or APT repository output.

Useful build commands:

```sh
cmake -S . -B build -D_TARGET_NAME=main
cmake --build build
cmake -S . -B build-firewalld -D_TARGET_NAME=firewalld
cmake --build build-firewalld
```

Check `build.conf` before building. `CONFIG_ARCH` controls whether the CMake toolchain uses x86 or ARM compilers.

Useful Dart and Flutter commands:

```sh
cd themis_ui_lib && dart pub get && dart test
cd themis_cli && dart pub get && dart test
cd themis_gui && flutter pub get && flutter test
```

## Coding Guidelines

- Follow the existing local style before introducing new abstractions.
- C++ code uses C++23 and the project's Linux-style formatting conventions.
- Use `snakeCase` for normal variables, `m_VariableName` for member variables, and `s_MemberName` for static variables.
- Keep plugin behavior explicit: document D-Bus names, HTTP routes, config files, filesystem writes, and service assumptions.
- Prefer typed parsing and structured JSON handling over ad hoc string parsing when practical.
- Keep UI schema changes compatible with both `themis_gui` and `themis_cli` unless the issue explicitly approves a break.
- Avoid committing generated build output, local machine paths, credentials, tokens, or private service details.

## Commit Messages

Use short, action-oriented commits. The current project convention is:

```text
* add: Short description of what was added
* fix: Short description of what was fixed
```

For larger work, split commits by logical change: server behavior, plugin behavior, UI update, docs, and tests.

## Testing Expectations

Choose verification based on the change:

- C++ server or component change: build the relevant CMake target and manually verify the affected HTTP or D-Bus path when possible.
- Plugin change: build the plugin target, verify its `ui.json`, test config read/write behavior, and check service-specific assumptions.
- Dart library or CLI change: run `dart test` in the affected package.
- Flutter GUI change: run `flutter test` and manually check the affected screen or workflow when possible.
- Packaging change: run the relevant script in `scripts` and inspect the generated Debian metadata or APT output.
- Documentation-only change: proofread links, commands, paths, and examples.

If a test cannot be run locally, say why in the pull request and include the best manual verification you could perform.

## Pull Request Checklist

- Link the related issue or explain why the change is small enough not to need one.
- Describe what changed and why.
- List commands or manual steps used for verification.
- Include screenshots for visible GUI changes and logs for service, D-Bus, HTTP, or packaging behavior.
- Note compatibility, migration, security, or privilege implications.
- Update docs, templates, examples, or plugin UI JSON when user-facing behavior changes.
- Keep pull requests focused. Separate unrelated refactors from behavior changes.

## Security and Responsible Disclosure

Project Themis may interact with system services, local configuration files, remote access workflows, and privileged installation paths. Do not publish secrets, exploit-ready details, private infrastructure names, or credentials in public issues. If a report may affect user security, open a minimal issue asking maintainers for a private disclosure path, or contact a maintainer directly if you already have one.

## Community Standards

Be respectful, specific, and collaborative. Good contributions explain the problem, the tradeoffs, and how the result was verified. Reviews should focus on correctness, maintainability, user safety, and keeping Themis approachable for the next contributor.
