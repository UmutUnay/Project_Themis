---
name: Bug report
about: Report a reproducible problem in Themis.
title: "[Bug]: "
labels: bug, triage
assignees: ""
---

## Summary

<!-- What broke? Keep this short and specific. -->

## Affected Area

- [ ] Themis server
- [ ] HTTP API
- [ ] D-Bus communication
- [ ] Plugin lifecycle or installation
- [ ] Firewalld plugin
- [ ] Apache plugin
- [ ] Remote access tool plugin
- [ ] CLI or TUI
- [ ] Flutter GUI
- [ ] Shared UI library
- [ ] Debian/APT packaging
- [ ] Build system or generated config
- [ ] Other

## Environment

- Themis version or commit:
- OS and distribution:
- Architecture: <!-- x86, ARM, arm64, amd64, other -->
- Install method: <!-- source build, .deb, APT repo, local binary, other -->
- Build target: <!-- main, firewalld, apache, remote_access_tool_plugin, other -->
- Server address and port: <!-- default is http://127.0.0.1:5000 -->
- Dart/Flutter version, if UI or CLI related:
- Relevant service/plugin:

## Steps to Reproduce

1. 
2. 
3. 

## Expected Behavior

<!-- What should have happened? -->

## Actual Behavior

<!-- What happened instead? Include exact errors where possible. -->

## Logs and Evidence

<!-- Paste short logs only. Attach files or screenshots for longer output. -->

```text

```

## Regression

- [ ] This worked in an earlier version.
- [ ] This is a new feature or code path.
- [ ] I do not know.

If known, last working version or commit:

## Impact

- [ ] Blocks normal use
- [ ] Breaks a plugin
- [ ] Breaks server startup
- [ ] Breaks CLI or GUI workflow
- [ ] Breaks packaging or installation
- [ ] Data loss or config corruption risk
- [ ] Security or privilege boundary concern
- [ ] Minor or cosmetic issue

## Workaround

<!-- Is there a temporary workaround? Write "None known" if not. -->

## Suggested Fix

<!-- Optional. Share code pointers, suspected files, or possible causes. -->

## Checklist

- [ ] I searched existing issues and pull requests.
- [ ] I can reproduce this on the version or commit listed above.
- [ ] I included the exact command, route, plugin action, or UI path that triggers the bug.
- [ ] I removed secrets, tokens, local credentials, and private hostnames.
