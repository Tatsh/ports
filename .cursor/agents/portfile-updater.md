---
name: portfile-updater
description: Update a port to a new version using livecheck, refresh checksums and go.vendors, test build and destroot, then commit with a version-update message.
---

# Portfile updater

Update a port to a newer version: run livecheck, update the Portfile (version, checksums, and for Go ports the `go.vendors` section), verify the port builds and completes the destroot phase, then commit the changes with a standardized message.

## When to use this agent

Use this agent when you want to bump a port to a new upstream version. It covers checking for updates, updating the Portfile and checksums (and Go vendor data when applicable), testing, and committing on success.

## Prerequisites

- MacPorts (or compatible) ports tree with the `port` command available.
- The port to update identified (e.g. path `category/portname` or port name).
- For Go ports: `go2port` available if you use it to update `go.vendors`.

## Update procedure

### 1. Change into the port directory

Change into the directory that contains the port’s `Portfile` (e.g. `category/portname` under the ports tree root).

```bash
cd category/portname
```

Or with an absolute path:

```bash
cd /path/to/ports/category/portname
```

### 2. Run livecheck

Check what version upstream reports and whether the port is outdated:

```bash
port livecheck
```

- Note the **current** version (from the Portfile) and the **new** version reported by livecheck, if any.
- If livecheck reports a new version, proceed. If it says the port is up to date or livecheck fails, resolve or stop as appropriate.

### 3. Update the port and checksums

Update the Portfile with the new version (and any `distname`/distfile name changes) as needed, then refresh checksums:

```bash
port -v checksum
```

- This fetches distfiles (if needed) and computes new checksums.
- **Update the Portfile** with the new checksum values (e.g. `checksums` with updated `rmd160`, `sha256`, and `size`). Replace the old checksum block with the values printed or written by `port checksum`.

### 4. Go ports: update `go.vendors`

If the port is a **Go** package that uses a `go.vendors` section, that section must be updated for the new version.

- Run **`go2port update`** (from the port directory) to refresh vendor data; it can update or generate the `go.vendors` block.
- Edit the Portfile so the `go.vendors` section matches the updated output (add, remove, or update entries as needed).

### 5. Test the port

Verify the port builds and completes the destroot phase. Tests are optional for this agent—they are allowed to fail; only build and destroot must succeed.

1. Clean and run destroot:

   ```bash
   port clean --all
   port -v destroot
   ```

2. If `port -v destroot` exits with a non-zero status, the update has failed; fix the Portfile or dependencies and retry. Do not commit until destroot succeeds.

3. Optionally run tests (failures do not block the update):

   ```bash
   port -v test
   ```

### 6. Commit the changes

Only if the port **successfully builds and completes the destroot phase**, commit the changes. Use this message format:

```
{package_name}: update to {new_version}.
```

- **{package_name}** — the port name (e.g. from the Portfile `name` or the directory name, as used in the tree).
- **{new_version}** — the new upstream version you updated to (e.g. from livecheck).

Example:

```
wget: update to 1.24.1.
```

Commit only the files that are part of the version bump (typically the Portfile; include any modified or added patch/files if applicable).

## Summary checklist

1. **cd** into the port directory.
2. Run **`port livecheck`** and note current vs new version.
3. Update **version** (and distfile names if needed) in the Portfile.
4. Run **`port -v checksum`** and update the **Portfile** with the new checksums.
5. For **Go** ports: run **`go2port update`** and update the **`go.vendors`** section in the Portfile.
6. Run **`port clean --all`** then **`port -v destroot`**; ensure destroot **succeeds** (tests may fail).
7. **Commit** with message: **`{package_name}: update to {new_version}.`**

## Notes

- Always run `port` from the port directory so the correct Portfile is used.
- If livecheck does not detect the new version, you may need to adjust `livecheck` settings in the Portfile.
- For Go ports, an outdated `go.vendors` section can cause build or checksum mismatches; keep it in sync with the new version.
- Do not commit if destroot fails; fix the port first and re-run the test steps.
