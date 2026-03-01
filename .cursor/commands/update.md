# Update Port

## Overview

Update a port to a newer upstream version: run livecheck, update the Portfile (version and checksums; for Go ports also `go.vendors`), verify build and destroot succeed, then commit with a standardized message. Anything you type after `/update` (e.g. a port path like `net/wget`) is passed as context—use it to specify which port to update.

## Steps

1. **Change into the port directory**
   - Use the path provided after the command or the current context (e.g. `category/portname`).
   - Example: `cd net/wget` or `cd /path/to/ports/category/portname`.

2. **Run livecheck**
   - Run: `port livecheck`
   - Note the current version (from the Portfile) and the new version reported. If no update is reported or livecheck fails, resolve or stop.

3. **Update the port and checksums**
   - Update the Portfile with the new version (and any `distname`/distfile name changes).
   - Run: `port -v checksum`
   - Update the Portfile with the new checksum values (rmd160, sha256, size) from the output.

4. **Go ports: update go.vendors**
   - If the port is a Go package with a `go.vendors` section, run `go2port update` from the port directory.
   - Edit the Portfile so the `go.vendors` section matches the updated output.

5. **Test the port**
   - Run: `port clean --all` then `port -v destroot`
   - Destroot must succeed. If it fails, fix the Portfile and retry; do not commit.
   - Optionally run `port -v test` (test failures do not block the update).

6. **Commit the changes**
   - Only if build and destroot succeeded.
   - Commit with message: `{package_name}: update to {new_version}.`
   - Example: `wget: update to 1.24.1.`
   - Commit only files that are part of the version bump (typically the Portfile).

## Checklist

- [ ] cd into the port directory
- [ ] Run `port livecheck` and note current vs new version
- [ ] Update version (and distfile names if needed) in the Portfile
- [ ] Run `port -v checksum` and update the Portfile with new checksums
- [ ] For Go ports: run `go2port update` and update the `go.vendors` section
- [ ] Run `port clean --all` then `port -v destroot`; destroot succeeds
- [ ] Commit with message `{package_name}: update to {new_version}.`
