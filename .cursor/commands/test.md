# Test Port

## Overview

Test a port by cleaning, running the destroot phase (and test phase if present), then reporting
whether destroot succeeded, whether the destroot content looks correct, and—if the port has a test
phase—whether the tests passed. Anything you type after `/test` (e.g. a port path like `net/wget`)
is passed as context—use it to specify which port to test.

## Steps

1. **Change into the port directory**
   - Use the path provided after the command or the current context (e.g. `category/portname`).
   - Example: `cd net/wget` or `cd /path/to/ports/category/portname`.

2. **Clean the port**
   - Run: `port clean --all`

3. **Run destroot**
   - Run: `port -v destroot`
   - If non-zero exit: destroot **failed**—note the error output.
   - If zero exit: destroot **succeeded**—continue.

4. **Run tests (if the port has a test phase)**
   - If the port defines a test phase (e.g. `test.run yes`), run: `port -v test`
   - If non-zero exit: tests **failed**—note the output.
   - If zero exit: tests **passed**.

5. **Report back**
   - **Destroot result:** Success or failure (and brief reason if failure).
   - **Destroot content:** Whether staged files look correct (expected bins/libs/headers/data; any issues).
   - **Test result (if applicable):** Passed, failed, or no test phase—with brief detail if failed.

## Report format

- **Destroot:** Success / Failure — [brief reason if failure]
- **Destroot content:** Looks correct / Issues found — [brief description]
- **Tests:** Not present / Passed / Failed — [brief reason if failed]

## Checklist

- [ ] cd into the port directory
- [ ] Run `port clean --all`
- [ ] Run `port -v destroot` and confirm success
- [ ] If test phase exists, run `port -v test`
- [ ] Report destroot result, destroot content, and test result
