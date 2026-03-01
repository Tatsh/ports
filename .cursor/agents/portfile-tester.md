---
name: portfile-tester
description: Test a port by running clean, destroot, and optionally test; report success and destroot correctness.
---

# Portfile tester

Test a port by cleaning, running the destroot phase (and test phase when present), then reporting whether destroot succeeded, whether the destroot content looks correct, and—if the port has a test phase—whether the tests passed.

## When to use this skill

Use this skill when you want to verify that a port builds and stages correctly, and that its test phase (if any) passes. Typical cases: after editing a Portfile, before submitting a change, or when debugging a failing port.

## Prerequisites

- You must be in a MacPorts (or compatible) ports tree with the `port` command available.
- The port to test must be identified (e.g. by path such as `net/wget` or by port name).

## Test procedure

### 1. Change into the port directory

Change into the directory that contains the port’s `Portfile`. For a port like `net/wget`, that is the directory `net/wget` under the root of the ports tree.

```bash
cd /path/to/ports/net/wget
```

Or, if the workspace root is the ports tree:

```bash
cd net/wget
```

### 2. Clean the port

Run a full clean so the test starts from a clean build state:

```bash
port clean --all
```

### 3. Run destroot

Run the destroot phase with verbose output:

```bash
port -v destroot
```

- If the command exits with a non-zero status, destroot **failed**; note the error output.
- If it exits with status zero, destroot **succeeded**; continue to the next step.

### 4. Run tests (if the port has a test phase)

If the port defines a test phase (e.g. `test.run yes` or a custom test phase), run:

```bash
port -v test
```

- If the command exits with a non-zero status, tests **failed**; note the failure output.
- If it exits with status zero, tests **passed**.

To determine whether the port has a test phase, you can inspect the Portfile for test-related keywords (e.g. `test.run`, `test.target`) or run `port -v test` and interpret the result (e.g. “no test phase” vs actual test run).

### 5. Report back

Provide a concise report that includes:

1. **Destroot result**  
   - Whether `port -v destroot` succeeded or failed.  
   - If it failed, summarize the error (e.g. missing dependency, build failure, destroot script error).

2. **Destroot content**  
   - Whether the destroot content looks correct (e.g. expected binaries, libraries, headers, and data under the destroot directory).  
   - Mention any obvious problems: missing files, wrong paths, unexpected or duplicate files.  
   - The destroot directory is typically under the port’s work path (e.g. under `$prefix/var/macports/build/...` or the path shown in `port -v destroot` output).

3. **Test result (if applicable)**  
   - If the port has a test phase: whether `port -v test` passed or failed.  
   - If it failed, summarize the failure (e.g. failing test name or error message).  
   - If the port has no test phase, state that and skip this part.

## Example report format

- **Destroot:** Success / Failure — [brief reason if failure]
- **Destroot content:** Looks correct / Issues found — [brief description]
- **Tests:** Not present / Passed / Failed — [brief reason if failed]

## Notes

- Always run from the port directory so `port` targets apply to that port.
- `port clean --all` removes build and destroot artifacts; use it to avoid stale state.
- Verbose output (`-v`) is important for diagnosing failures; include relevant lines when reporting.
