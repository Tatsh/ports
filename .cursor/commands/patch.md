# Create Patches for a Port

## Overview

Create source-code patches for a port so it builds and destroots successfully. Follow the patch-creation steps from the portfile-editor skill: clone or set up the source, make minimal changes, generate patches, add them to the port, then test. Retry with fixes (new or updated patches, or Portfile changes) until the port works, up to **50 tries**. If it still fails, or the failure is due to an incompatible SDK on this machine and the source cannot be back-patched, give up. **Never commit non-working ports.**

Anything you type after `/patch` (e.g. a port path like `aqua/EnvPane`) is passed as context—use it to specify which port to patch.

## Prerequisites

- The port must already exist (Portfile and optionally a `files/` directory).
- You need the upstream tag or commit the port uses (from the Portfile or `port info`).

## Steps

### 1. Set up the source repository

- **If the port uses a Git-based fetch (e.g. GitHub):**
  - Clone the package repository to `~/dev/macports/patched-src-repos`. Prefer SSH URIs (e.g. `git@github.com:user/repo.git`).
  - In the clone: checkout the **target tag or commit** used by the port (e.g. the version or SHA in the Portfile).
  - Create and checkout a new branch: `macports`.
- **If the source is only a tarball:**
  - Download and unpack the tarball into `~/dev/macports/patched-src-repos/<name-of-package>`.
  - Run `git init` and create the first commit with the source unchanged.

### 2. Make changes and commit

- In the source repo, make changes required for the port to build (e.g. MacPorts paths, code sign, remove Sparkle/auto-updater, fix build for our prefix). This could include back-porting patches for the current OS.
- Commit changes with Git. Use **logical grouping**—each commit will become one patch.
- Reference: “Creating source code patches” and “What to always patch” in the portfile-editor skill.

### 3. Generate patches

In the source repository (on the `macports` branch, with your commits on top of the target tag/commit):

```shell
rm -fR patches/
mkdir patches
git format-patch -q --filename-max-length 40 -o patches/ "${target_tag_or_commit}"
```

Use the same `${target_tag_or_commit}` the port uses (e.g. tag `1.2.0` or commit `cb277da`).

### 4. Add patches to the port

- Copy the generated patch files from `patches/` into the port’s **files** directory:
  - `category/package-name/files/` (e.g. `aqua/EnvPane/files/`).
- Old, irrelevant patches should be deleted.
- In the Portfile, add or update:
  - `patchfiles` or `patchfiles-append` with the patch filenames.
  - `patch.pre_args` if needed (e.g. `-p1` or `-p0`).

### 5. Test the port (and repeat up to 50 times)

- Run: `port clean --all` then `port -v destroot` for the port (e.g. `port -v destroot category/portname`).
- **If destroot succeeds:** the port works. You may proceed to commit (using the commit command; never commit non-working ports).
- **If destroot fails:**
  - **Attempts 1–50:** Diagnose the failure. If it is due to:
    - **Patch apply failure:** Fix patch context or `patch.pre_args`; or adjust changes in the source repo and regenerate patches.
    - **Build/destroot failure:** Fix the source (in `~/dev/macports/patched-src-repos`), recommit, regenerate patches, update the port’s `files/` and Portfile, then run `port clean --all` and `port -v destroot` again.
    - **SDK / Xcode error on this machine** (e.g. “SDK lookup failed”, or build requires a newer macOS/Xcode than available): If the source **cannot** be back-patched to work on this OS, **give up** for this port; do not commit.
  - Increment the attempt count. After **50 attempts** without a successful destroot, **give up**; do not commit.

### 6. When to stop without committing

- Destroot still fails after 50 tries.
- Failure is clearly due to an incompatible SDK (or similar environment) on this machine and the upstream source cannot be reasonably back-patched.

In these cases, do **not** commit. You may leave the Portfile and `files/` in a working tree for later or document the blocker.

## Checklist

- [ ] Source repo cloned/set up in `~/dev/macports/patched-src-repos` at correct tag/commit; branch `macports` created
- [ ] Changes committed in source repo (logical grouping per patch)
- [ ] Patches generated with `git format-patch -q --filename-max-length 40 -o patches/ "${target_tag_or_commit}"`
- [ ] Patches copied to port’s `files/` and listed in Portfile (`patchfiles` / `patchfiles-append`, `patch.pre_args` if needed)
- [ ] `port clean --all` then `port -v destroot` run; destroot succeeds within 50 attempts (or give up as above)
- [ ] Non-working ports are never committed
