# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# Install a Node.js tool from a prebuilt node_modules tarball, the way tatsh-overlay's
# nodejs-mod eclass does on Gentoo: no npm install (and so no network) at build time.
#
# The tarball, ${name}-${version}-node_modules.tar.xz, is a ${name}-${version} directory with
# the package.json, the lockfile and a complete node_modules. tatsh-overlay publishes them as
# assets of its __distfiles__ release, which is the default master site. The tree is installed
# as ${prefix}/lib/node_modules/${name}, and each entry of nodejs.bins is linked into
# ${prefix}/bin with its shebang pointed at the node of the nodejs port.
#
# Packages without native addons are noarch. A package with addons sets nodejs.native yes: its
# binding.gyp directories are rebuilt with node-gyp, and prebuilt binaries for other platforms are
# removed (they are dead weight, and rev-upgrade would report them). node-gyp needs Node's headers
# tarball (with common.gypi, which the nodejs port does not install); it is fetched as a distfile
# for nodejs.headers_version, which only has to match the major version (the addon ABI) of the
# nodejs port, so such ports also list node-v<version>-headers.tar.gz in their checksums.
#
# Usage:
#   PortGroup               nodejs 1.0
#   name                    prettier
#   version                 3.10.1
#   nodejs.bins             {prettier node_modules/prettier/bin/prettier.cjs}
#   nodejs.native           no              ;# yes when the package has native addons

options nodejs.version nodejs.headers_version nodejs.bins nodejs.native nodejs.dir
default nodejs.version      22
default nodejs.headers_version 22.23.4
default nodejs.bins         {}
default nodejs.native       no
default nodejs.dir          {${prefix}/lib/node_modules/${name}}

categories          devel
maintainers         {gmail.com:audvare @Tatsh} openmaintainer
platforms           {darwin any}
supported_archs     noarch

master_sites        https://github.com/Tatsh/tatsh-overlay/releases/download/__distfiles__/
default distname    {${name}-${version}-node_modules}
use_xz              yes
default worksrcdir  {${name}-${version}}

use_configure       no
build {}

namespace eval nodejs {}

proc nodejs::add_dependencies {} {
    global prefix
    set v [option nodejs.version]
    depends_lib-delete      path:bin/node:nodejs${v}
    depends_lib-append      path:bin/node:nodejs${v}
    if {[option nodejs.native]} {
        set gyp lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js
        depends_build-delete    path:${gyp}:npm11 port:python313
        depends_build-append    path:${gyp}:npm11 port:python313
        supported_archs         x86_64 arm64
        set hv [option nodejs.headers_version]
        master_sites-append     https://nodejs.org/dist/v${hv}/:nodeheaders
        distfiles-append        node-v${hv}-headers.tar.gz:nodeheaders
        # use_xz would run xz on this gzip tarball too; extract it in post-extract.
        extract.only            [option distname][option extract.suffix]
    }
}

post-extract {
    if {[option nodejs.native]} {
        set headers ${distpath}/node-v[option nodejs.headers_version]-headers.tar.gz
        system -W ${workpath} "/usr/bin/tar -xzf [shellescape ${headers}]"
    }
}
port::register_callback nodejs::add_dependencies

# The prebuilds/<platform>-<arch> directory for this build.
proc nodejs::platform {} {
    global configure.build_arch
    set arch [expr {${configure.build_arch} eq "arm64" ? "arm64" : "x64"}]
    return darwin-${arch}
}

pre-build {
    if {[option nodejs.native]} {
        set gyp ${prefix}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js
        fs-traverse -depth f ${worksrcpath}/node_modules {
            if {[file tail ${f}] eq "binding.gyp" && [file isfile ${f}]} {
                set dir [file dirname ${f}]
                ui_info "--->  Building the native addon in [string range ${dir} [string length ${worksrcpath}/] end]"
                # The headers' config.gypi is not from a clang build, so common.gypi leaves the
                # C++ standard at the compiler default (gnu++98 for Apple clang); give Node's own
                # (an addon that asks for a newer one still gets it, as its flag comes later).
                system -W ${dir} "env CXXFLAGS=-std=gnu++17 ${prefix}/bin/node ${gyp} rebuild --nodedir=${workpath}/node-v[option nodejs.headers_version] --python=${prefix}/bin/python3.13"
            }
        }
    }
}

destroot {
    set dest ${destroot}[option nodejs.dir]
    file mkdir [file dirname ${dest}]
    copy ${worksrcpath} ${dest}
    if {[option nodejs.native]} {
        set keep [nodejs::platform]
        foreach dir [glob -nocomplain -type d ${dest}/node_modules/*/prebuilds/* \
                         ${dest}/node_modules/@*/*/prebuilds/*] {
            if {[file tail ${dir}] ne ${keep}} {
                delete ${dir}
            }
        }
    }
    xinstall -d ${destroot}${prefix}/bin
    foreach {bin path} [join [option nodejs.bins]] {
        set target ${dest}/${path}
        if {![file exists ${target}]} {
            return -code error "nodejs.bins: ${path} is not in the package"
        }
        file attributes ${target} -permissions 0755
        reinplace -q "1s|^#!.*node.*\$|#!${prefix}/bin/node|" ${target}
        ln -s [option nodejs.dir]/${path} ${destroot}${prefix}/bin/${bin}
    }
}

livecheck.type      none
