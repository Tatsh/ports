# Commit Port Changes

## Overview

Commit changes to the ports tree using a **standardised message format**. Use this command only
after the port has been verified to work (destroot succeeds). **Non-working ports must never be
committed.**

Anything you type after `/commit` (e.g. the commit message or port path) is passed as context—use
it to specify the message and, if needed, the port.

## Message format

Use this format for the commit message:

```text
{package_name}: {message}
```

- **{package_name}** is the port name (e.g. `wget`, `EnvPane`, `dockutil`). Use the value of the
  Portfile `name` keyword; for subports, use the subport name if the change is specific to it.
- **{message}** is a short, imperative description (e.g. `update to 1.24.1`, `add patch for
MacPorts paths and code sign`).

Examples:

- `wget: update to 1.24.1.`
- `EnvPane: add patch for MacPorts paths and code sign.`
- `dockutil: update to 3.1.3, use tarball_from tarball.`

## Rules

1. **Only commit working ports.** Before committing:
   - Run `port clean --all` then `port -v destroot` for the port.
   - Commit only if destroot **succeeds**. If it fails, fix the port (or patches) and retry; do
     not commit until it works.

2. **Use the standardised format.** Every commit message must start with `{package_name}:` and then
   the message.

3. **Scope the commit.** Include only files that are part of the change (e.g. Portfile and, if
   applicable, files in `files/`).

## Steps

1. **Verify the port works**
   - From the ports tree root: `port clean --all` for the port, then `port -v destroot` (e.g.
     `port -v destroot category/portname`).
   - If destroot fails, do **not** commit. Fix the port and repeat until destroot succeeds.

2. **Stage the right files**
   - Stage only the files you changed (e.g. `category/portname/Portfile`,
     `category/portname/files/*.diff`).

3. **Commit with the standardised message**
   - Run: `git commit -m "{package_name}: {message}"`
   - Example: `git commit -m "wget: update to 1.24.1."`

## Checklist

- [ ] `port clean --all` then `port -v destroot` for the port; destroot **succeeded**
- [ ] Commit message is in the form `{package_name}: {message}`. Must not end in a `.`.
- [ ] Only files that are part of this change are staged and committed
