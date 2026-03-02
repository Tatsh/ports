---
name: portfile-editor
description: Create or edit a Portfile for a package, creating patches where necessary.
---

# Portfile editor

Create or edit a Portfile for a package, creating patches where necessary.

This skill is adapted from [MacPorts Guide](https://guide.macports.org/).

## Portfile introduction

A port is a distribution of software that can be compiled and installed using MacPorts. A Portfile
describes all the required steps such as where to get the source code from upstream, which patches
have to be applied and which other tools and commands are required to build the source code.

A MacPorts Portfile is a Tcl script that usually contains only the simple keyword/value combinations
and Tcl extensions as described in the Portfile Reference chapter, though it may also contain
arbitrary Tcl code. Every port has a corresponding Portfile, but Portfiles do not completely
define a port's installation behavior since MacPorts base has default port installation
characteristics coded within it. Therefore Portfiles need only specify required options, though
some ports may require non-default options.

A common way for Portfiles to augment or override MacPorts base default installation phase
characteristics is by using Portfile phase declaration(s). If you use Portfile phase declaration(s),
you should know how to identify the “global” section of a Portfile. Any statements not contained
within a phase declaration, no matter where they are located in a Portfile, are said to be in the
global section of the Portfile; therefore the global section need not be contiguous. Likewise, to
remove statements from the global section they must be placed within a phase declaration.

The main phases you need to be aware of when making a Portfile are these:

- Fetch
- Extract
- Patch
- Configure
- Build
- Destroot

The default installation phase behaviour performed by the MacPorts base works fine for applications
that use the standard configure, make, and make install steps, which conform to phases configure,
build, and destroot respectively. For applications that do not conform to this standard behavior,
any installation phase may be augmented using pre- and/or post- phases, or even overridden or
eliminated.

## Location

A package is a directory containing a `Portfile` file. For example, `net/wget`.

All packages must go in a category directory such as `aqua`, `net`, etc. Categories and what they
are used for:

- `aqua` - contains native macOS applications. This should be the go-to location if the application
  being built is primarily a native Cocoa application.
- `archivers` - tools involved in compression such as `zip`.
- `audio` - audio manipulation tools that do not support video and are non-native macOS applications
  (CLI or uses another toolkit in X11 such as Gtk+).
- `cad`
- `databases`
- `devel` - Development tools and libraries that do not fit in another category. Usually any C/C++
  library.
- `editors` - Text editors.
- `emulators` - Any kind of emulator such as a video game console emulator.
- `fonts`
- `games`
- `graphics` - Graphics-related utilities.
- `java` - Libraries for Java.
- `kde` - Applications that use the KDE frameworks.
- `lang` - Interpreters and compilers.
- `llm`
- `lua` - Lua libraries.
- `math` - Maths-related tools and libraries.
- `multimedia` - Tools that support video and audio such as a `ffmpeg`.
- `net` - Network non-WWW utilities such as `ngrep`.
- `office` - Packages related to office work including LibreOffice.
- `perl` - Libraries for Perl.
- `print` - Packages related to printing such as CUPS, Ghostscript, etc.
- `python` - Libraries for Python.
- `ruby` - Libraries for Ruby.
- `scheme` - Libraries for Scheme-based languages.
- `science` - Applications used in biology, chemistry, physics, etc.
- `security` - System utilities that are security-related.
- `sysutils` - System utilities that do not fit in another category.
- `www` - Web browsers and downloaders, etc.
- `x11` - Tools that run in the X11 environment.

## Naming

- If a package name contains spaces and it is not an `aqua` app, spaces should be replaced with `-`.
  'My App' becomes `my-app`. If `aqua`, 'My App' becomes 'my-app'. However, if the name of the
  primary target is `MyApp` then the package name should also be `MyApp`.
- Any non-ASCII non-numeric characters should be removed from the name.
- Replace `_` with `-`.

## Clone the target package repository

If applicable, clone the package repository to `~/dev/macports/patched-src-repos`. Prefer to use
SSH URIs over HTTPS. After cloning, checkout to the target tag or commit and then checkout to a new
branch `macports`.

If a project uses Swift Package Manager (SPM) for dependencies or build, that version cannot be
packaged for MacPorts. Use the version prior to the switch to SPM if it exists; that is the highest
usable version.

If the source is provided only as a tarball, download and unpack the tarball into
`~/dev/macports/patched-src-repos/name-of-package` (create subdirectory `name-of-package` if
necessary). Run `git init` and create the first commit containing the source unchanged.

## Portfile structure

After examining the source code of the package, look for existing ports that may fit the use case.
For example, if the package is a Python package, it will likely go into `python` category so have a
look at packages there. If the package uses CMake to build, search for packages that use the `cmake`
PortGroup.

Check the list of PortGroups in
`/opt/local/var/macports/sources/rsync.macports.org/macports/release/tarballs/ports/_resources/port1.0/group/`
to see if one can make creating a Portfile easier before considering writing any phases. In many
cases, for simpler packages, when a PortGroup is used only metadata is required and no phases have
to be written.

Note that a lot of time, Xcode-based projects must perform several tasks in a single phase. We
usually make `build` a blank phase and allow `xcodebuild` to run in `destroot`. This is demonstrated
in several packages such as `aqua/Flycut/Portfile`.

These are the basic parts of a Portfile, in order:

1. Modeline

   ```tcl
   # -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
   ```

1. PortSystem line:

   ```tcl
   PortSystem          1.0
   ```

1. Port name:

   ```tcl
   name                rrdtool
   ```

1. Port version:

   ```tcl
   version             1.2.23
   ```

1. Port category: A port may belong to more than one category, but the first (primary) category
   should match the directory name in the ports tree where the Portfile is to reside.

   ```tcl
   categories          net
   ```

1. Platform statement:

   ```tcl
   platforms           darwin
   ```

1. Port maintainers: A port's maintainers are the people who have agreed to take responsibility for
   keeping the port up-to-date. The maintainers keyword lists the maintainers' GitHub usernames or
   email addresses, preferably in the obfuscated form which hides them from spambots.

   ```tcl
   maintainers         @neverpanic \
                       jdoe \
                       example.org:julesverne
   ```

1. Port description (always end with a `.`):

   ```tcl
   description         Round Robin Database
   ```

1. Long description (always end with a `.`):

   ```tcl
   long_description    RRDtool is a system to store and display time-series \
                       data.
   ```

1. Homepage:

   ```tcl
    homepage            https://people.ee.ethz.ch/~oetiker/webtools/rrdtool/
   ```

1. Port's download URLs: These are the download location or mirrors without the package filename.

   ```tcl
   master_sites        https://oss.oetiker.ch/rrdtool/pub/ \
                       ftp://ftp.pucpr.br/rrdtool/
   ```

1. Port checksums:

   ```tcl
   checksums               rmd160  7bbfce4fecc2a8e1ca081169e70c1a298ab1b75a \
                           sha256  2829fcb7393bac85925090b286b1f9c3cd3fbbf8e7f35796ef4131322509aa53 \
                           size    1061530
   ```

   To find the correct checksums, use `openssl`:

   ```shell
   openssl dgst -rmd160 rrdtool-1.2.23.tar.gz
   openssl dgst -sha256 rrdtool-1.2.23.tar.gz
   ```

1. Port dependencies:

   ```tcl
   depends_lib         port:perl5.8 \
                       port:tcl \
                       port:zlib
   ```

   `depends_lib` is for dependencies that are required both at runtime and at build time.
   `depends_run` is for dependencies only required at runtime. `depends_build` is for dependencies
   only required at build time. If using a PortGroup to assist in building, prefer to use the
   correct command but with `-append` added: `depends_lib-append mydep`.

1. Configure arguments (optional):

   ```tcl
   configure.args      --enable-perl-site-install \
                       --mandir=${prefix}/share/man
   ```

### Augmenting phases using pre- and post-

```tcl
post-destroot {
    # Install example files not installed by the Makefile
    file mkdir ${destroot}${prefix}/share/doc/${name}/examples
    file copy ${worksrcpath}/examples/ \
        ${destroot}${prefix}/share/doc/${name}/examples
}
```

### Overriding phases

```tcl
destroot {
    xinstall -m 755 -d ${destroot}${prefix}/share/doc/${name}
    xinstall -m 755 ${worksrcpath}/README ${destroot}${prefix}/share/doc/${name}
}
```

### Eliminating phases

```tcl
build {}
```

### Creating a startup item

Startupitems may be placed in the global section of a Portfile.

```tcl
startupitem.create      yes
startupitem.name        nmicmpd
startupitem.executable  "${prefix}/bin/nmicmpd"
```

## Port Variants

Variants are a way for port authors to provide options that may be invoked at install time. They are
declared in the global section of a Portfile using the `variant` keyword, and should include
carefully chosen variant descriptions.

### Example variants

The most common actions for user-selected variants is to add or remove dependencies, configure
arguments, and build arguments according to various options a port author wishes to provide. Here is
an example of several variants that modify `depends_lib` and configure arguments for a port.

```tcl
variant fastcgi description {Add fastcgi binary} {
    configure.args-append \
            --enable-fastcgi \
            --enable-force-cgi-redirect \
            --enable-memory-limit
}

variant gmp description {Add GNU MP functions} {
    depends_lib-append port:gmp
    configure.args-append --with-gmp=${prefix}

}

variant sqlite description {Build sqlite support} {
    depends_lib-append \
        port:sqlite3
    configure.args-delete \
        --without-sqlite \
        --without-pdo-sqlite
    configure.args-append \
        --with-sqlite \
        --with-pdo-sqlite=${prefix} \
        --enable-sqlite-utf8
}
```

### Variant Actions in a Phase

If a variant requires options in addition to those provided by keywords using `-append` and/or
`-delete`, in other words, any actions that would normally take place within a port installation
phase, do not try to do this within the variant declaration. Rather, modify the behavior of any
affected phases when the variant is invoked using the `variant_isset` keyword.

```tcl
post-destroot {
    xinstall -m 755 -d ${destroot}${prefix}/etc/
    xinstall ${worksrcpath}/examples/foo.conf \
        ${destroot}${prefix}/etc/

    if {[variant_isset carbon]} {
        delete ${destroot}${prefix}/bin/emacs
        delete ${destroot}${prefix}/bin/emacs-${version}
    }
}
```

### Default variants

Variants are used to specify actions that lie outside the core functions of an application or port,
but there may be some cases where you wish to specify these non-core functions by default. For this
purpose you may use the keyword `default_variants`.

```tcl
default_variants    +foo +bar
```

## Subports

MacPorts subports are a way of declaring multiple related ports in a single Portfile. It is
especially helpful to use subports when the related ports share variables or keywords, because they
can be declared in the shared part of the Portfile and used by each subport.

Because MacPorts treats each subport as a separate port declaration, each subport will have its own,
independent phases: fetch, configure, build, destroot, install, activate, etc. However, because the
subports share the global declaration part, all the subports will by default share the same
`dist_subdir`. This means that MacPorts only needs to fetch the distfiles once, and the remaining
subports can reuse the distfiles.

Note that Python packages are normally subports.

### Example

```tcl
Portfile                   1.0

name                       example

depends_lib                aaa
configure.args             --bbb

subport example-sub1 {
    depends_lib-append     ccc
    configure.args         --ddd
}

subport example-sub2 {
    depends_lib-append     eee
    configure.args-append  --fff
}
```

MacPorts will produce the same results as if there were three Portfiles:

```tcl
Portfile                   1.0

name                       example
# Note: For the parent port, 'subport' has the same value as 'name'.
# Also, one cannot override the subport name; it's shown here merely
# to illustrate what the value is set to, for the given context.
#subport                   example

depends_lib                aaa
configure.args             --bbb
```

```tcl
Portfile                   1.0

name                       example
# Value for 'subport' shown here for illustration purposes only; see note above.
#subport                   example-sub1

depends_lib                aaa
depends_lib-append         ccc
configure.args             --ddd
```

```tcl
Portfile                   1.0

name                       example
# Value for 'subport' shown here for illustration purposes only; see note above.
#subport                   example-sub2

depends_lib                aaa
depends_lib-append         eee
configure.args             --bbb
configure.args-append      --fff
```

## Creating source code patches

If a package does not build because of a missing dependency, run
`port install --unrequested dep-name` if the package is in MacPorts. If it is not in MacPorts, you
must create, test, and install the dependency package before you can continue. If the dependency
package in MacPorts is out-of-date, copy the existing package from MacPorts in this local Portfile
repository and update it.

After determining that a port will not build and with certainty that it is not because of an issue
in the Portfile, minimal patches should be made to the repository cloned or set up in
`~/dev/macports/patched-src-repos` then committed with Git. Then use
`git diff ${target_tag_or_commit}` to get the difference. Commits should be a logical grouping of changes.

Each commit should be a separate patch. To get all patches in order, use the following in the
source repository:

```shell
rm -fR patches/
mkdir patches
git format-patch -q --filename-max-length 40 -o patches/ "${target_tag_or_commit}"
```

Patches go in `files` directory for the package:

```plain
category/
  package-name/
    Portfile
    files/
      cool-patch.diff
```

They must be added to the port with the `patchfiles` or `patchfiles-append` command.

### What to always patch

- Completely remove use of Sparkle. The patch should be to add a build system option to make it
  entirely optional.
- Any kind of automatic updater functionality. Again, should be a configuration option.

## Portfile Best Practices

_Source: [MacPorts Guide - Portfile Best Practices](https://guide.macports.org/chunked/development.practices.html)_

Practical guidelines for creating Portfiles that install smoothly and provide consistency between
ports.

### Port Style

Portfiles may be thought of as a set of declarations rather than a piece of code. Format the
Portfile as if it were a table consisting of keys and values. The two columns should be separated
by spaces (not tabs); set your editor to use soft tabs. By default, the top line of all Portfiles
should use a modeline:

```tcl
# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
```

The left column should consist of single words, separated from the right side by spaces in
multiples of four. When items require multiple lines with line continuation, indent additional
lines to the same column that the right side begins on. When a key item such as a phase or variant
requires braces, the opening brace should appear on the same line and the closing brace on its own
line; the block is indented. Braces merely quoting strings (e.g. variant descriptions) stay on the
same line. For multiple items in the second column, place each on a new line with backslash
continuation and indent.

### Don't Overwrite Config Files

For packages that use a configuration file, avoid overwriting user changes on upgrade or reinstall:

```tcl
post-destroot {
    file rename ${destroot}${prefix}/etc/apcupsd/apcupsd.conf \
                ${destroot}${prefix}/etc/apcupsd/apcupsd.conf.sample
}

post-activate {
    if {![file exists ${prefix}/etc/apcupsd/apcupsd.conf]} {
        file copy ${prefix}/etc/apcupsd/apcupsd.conf.sample \
                  ${prefix}/etc/apcupsd/apcupsd.conf
    }
}
```

### Use Variables

Set variables so changing paths may be done in one place; use them anytime it makes updates
simpler (e.g. `distname ${name}-src-${version}`).

### Renaming or replacing a port

If you need to replace a port with another or rename it, mark the port with `replaced_by`.

1. Add `replaced_by foo` (where foo is the replacement port); on upgrade MacPorts will install the
   replacement.
2. Increase version, revision, or epoch so `port outdated` will suggest an upgrade.
3. Clear distfiles (`distfiles` with no value), delete `master_sites`, set `livecheck.type none`.
4. Add a `pre-configure` block with `ui_error` and `return -code error` so users who try to
   install the old port see a clear message.

**Shortcut:** Use the PortGroup `obsolete` to define a stub port that only informs users to
switch to another port:

```tcl
PortSystem          1.0
PortGroup           obsolete 1.0

name                skrooge-devel
replaced_by         skrooge
version             0.8.0-${svn.revision}
revision            2
categories          kde finance
```

### Removing a port

Consider replacing it by an alternative (see above). It is recommended to wait one year before
removing the port directory from the tree. If there is no replacement, the port can be deleted
immediately.

---

## Portfile Reference

_Source: [MacPorts Guide - Portfile Reference](https://guide.macports.org/chunked/reference.html)_

Reference for the major elements of a Portfile: port phases, dependencies, StartupItems, variables,
keywords, and Tcl extensions.

### Global Keywords

Keywords are used in the "global" and "variant" sections of Portfiles, not inside phase
declarations.

| Keyword                      | Description                                                                                                                                                                                                                                                            |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **PortSystem**               | First non-comment line; defines Portfile interpreter version (e.g. `1.0`).                                                                                                                                                                                             |
| **name**                     | Port name; use only alphanumeric, underscores, dashes, periods. For "+" in names use "x" (e.g. libstdcxx).                                                                                                                                                             |
| **version**                  | Software version; match upstream format; omit leading "v". When a library's install_name changes, bump revision of dependents.                                                                                                                                         |
| **revision**                 | Optional integer (default 0); increment when the port is updated without a version change. Set explicitly (even to 0) for clarity. Increase when installed files or behavior change; do not increase for build fixes, comment changes, or adding non-default variants. |
| **epoch**                    | Optional integer (default 0); increase when the new version compares _less_ than the old (e.g. 2.0-rc1 → 2.0, or 1.10 → 1.2). Once set, never remove.                                                                                                                  |
| **categories**               | Category list; first should match the directory name.                                                                                                                                                                                                                  |
| **maintainers**              | GitHub usernames (e.g. `@user`) or obfuscated email (`example.org:account`). `nomaintainer` / `openmaintainer` have special meaning.                                                                                                                                   |
| **description**              | Short sentence fragment.                                                                                                                                                                                                                                               |
| **long_description**         | One or more sentences; can use `\n` for newlines.                                                                                                                                                                                                                      |
| **homepage**                 | Primary project URL; prefer final URL (e.g. https, no redirect).                                                                                                                                                                                                       |
| **platforms**                | List of platforms: `darwin`, `macosx`, `freebsd`, `linux`, etc. Can use version ranges, e.g. `{darwin >= 12}` or `{darwin >= 10 < 20}`.                                                                                                                                |
| **supported_archs**          | CPU archs (e.g. arm64, x86_64); use `noarch` if no arch-specific files.                                                                                                                                                                                                |
| **license**                  | License name and version (e.g. `GPL-3`); use `+` for "or any later version".                                                                                                                                                                                           |
| **license_noconflict**       | List of dependencies that do not form a derivative work for binary distribution.                                                                                                                                                                                       |
| **use_xcode**                | Set `yes` if the port needs Xcode (e.g. xcodebuild).                                                                                                                                                                                                                   |
| **known_fail**               | Set `yes` if the port is known not to work.                                                                                                                                                                                                                            |
| **macosx_deployment_target** | macOS release to target.                                                                                                                                                                                                                                               |
| **installs_libs**            | Set `no` if the port does not install libraries/headers for dependents.                                                                                                                                                                                                |
| **add_users**                | List of usernames and settings (group, realname, home, shell, etc.) for user creation.                                                                                                                                                                                 |

### Global Variables

Available to any Portfile; all except `prefix` are read-only.

| Variable                               | Description                                               |
| -------------------------------------- | --------------------------------------------------------- |
| **prefix**                             | Installation prefix (e.g. `/opt/local`).                  |
| **portpath**                           | Full path to the Portfile.                                |
| **filesdir**                           | Path to files dir relative to portpath (default `files`). |
| **filespath**                          | Full path to files directory.                             |
| **workpath**                           | Full path to work directory.                              |
| **worksrcpath**                        | Full path to extracted source.                            |
| **destroot**                           | Path into which software is destrooted.                   |
| **distpath**                           | Location for downloaded distfiles.                        |
| **install.user** / **install.group**   | User/group at install time.                               |
| **os.platform**                        | e.g. darwin, freebsd.                                     |
| **os.arch**                            | powerpc, i386, arm.                                       |
| **os.version**                         | OS version (e.g. 12.3.0).                                 |
| **os.major**                           | Major OS version.                                         |
| **macos_version**                      | Full macOS version (e.g. 10.15.7).                        |
| **xcodeversion** / **xcodecltversion** | Xcode / Command Line Tools version.                       |
| **universal_possible**                 | Whether universal binaries are possible.                  |

### Port Phases

Main phases: **fetch** (download distfiles) → **checksum** → **extract** → **patch** →
**configure** → **build** → **test** (optional) → **destroot** → **install** (archive) →
**activate** (extract to prefix). Phases can be augmented with pre-/post- blocks or overridden in
the Portfile. The destroot phase stages files into an intermediate location; MacPorts then
archives and activates them.

**Keyword list modifiers:** `-append`, `-delete`, `-replace`, `-strsed`. Use `-append` for
configure flags and PortGroup dependencies so you don't overwrite defaults (e.g.
`configure.cflags-append`, `depends_lib-append`).

**Important phase-related keywords (summary):**

- **Fetch:** `master_sites`, `master_sites.mirror_subdir`, `patch_sites`, `distname`, `distfiles`,
  `dist_subdir`, `worksrcdir`, `fetch.type` (standard|git|svn|hg|cvs|bzr), and type-specific
  options (e.g. `git.url`, `git.branch`).
- **Checksum:** `checksums` (rmd160, sha256, size per file).
- **Extract:** `extract.suffix`, `extract.cmd`, `extract.args`/`pre_args`/`post_args`, `use_bzip2`,
  `use_xz`, `use_zip`, etc.
- **Patch:** `patchfiles`, `patch.dir`, `patch.cmd`, `patch.pre_args` (e.g. -p1).
- **Configure:** `use_configure`, `configure.cmd`, `configure.args`, `configure.env`,
  `configure.cflags`/`configure.ldflags`/`configure.cppflags` (prefer `-append`),
  `configure.cc`/`configure.cxx`, etc.
- **Build:** `build.cmd`, `build.args`, `build.target`.
- **Destroot:** `destroot.target`, `destroot.destdir`, `destroot.keepdirs`.

### Dependencies

- **depends_fetch** — needed to download distfiles; not needed after install.
- **depends_extract** — needed to unpack; not needed after install.
- **depends_build** — needed to build; not needed at runtime.
- **depends_lib** — needed at build and runtime (headers/libraries).
- **depends_test** — only for phase `test` when `test.run yes`.
- **depends_run** — needed at runtime only.

Prefer port dependencies: `port:name`. File dependencies: `bin:progname:port`, `lib:libname:port`,
`path:path/relative/to/prefix:port`.

---

## MacPorts Internals

_Source: [MacPorts Guide - MacPorts Internals](https://guide.macports.org/chunked/internals.html)_

File layout, configuration files, and fundamental port installation concepts.

### File Hierarchy (porthier)

Under `${prefix}` (default `/opt/local/`):

- **bin/** — Common utilities and applications
- **etc/** — Configuration files and scripts
- **include/** — C include files
- **lib/** — Archive libraries
- **libexec/** — Daemons and system utilities
- **Library/Frameworks/** — Native macOS frameworks
- **sbin/** — System/administration utilities
- **share/** — Architecture-independent data (doc, examples, info, locale, man, misc, src)
- **var/** — Logs, temp, spool; under var: **macports/** (build, distfiles, registry, software,
  sources, spool, log, run), **db/**, **www/**
- **/Applications/MacPorts/** — Native macOS applications

`${prefix}/var/macports`: `build/` (where ports are built and destrooted), `distfiles/`,
`registry/` (sqlite registry), `software/` (installed port files), `sources/` (ports tree and base).

### Configuration Files

All in `${prefix}/etc/macports`. Format: key/value pairs; lines starting with `#` are comments.

**macports.conf** — Bootstrap and general behavior: `prefix`, `portdbpath`, `build_arch`,
`applications_dir`, `frameworks_dir`, `developer_dir`, `buildfromsource` (always|never|ifneeded),
`portarchivetype`, `buildmakejobs`, `rsync_server`, `rsync_dir`, `binpath`, `host_blacklist`,
`preferred_hosts`, `universal_archs`, `startupitem_type`, `startupitem_install`, etc.

**sources.conf** — Defines ports tree sources. Default:
`rsync://rsync.macports.org/macports/release/tarballs/ports.tar [default]`. Local repos:
`file:///path/to/ports`.

**variants.conf** — Optional; global variants to apply; unsupported variants are ignored.
