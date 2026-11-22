# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# Build a libretro core with its own Makefile and install the <core>_libretro.dylib into
# ${prefix}/lib/libretro, the cores directory of the retroarch port. This is the MacPorts
# counterpart of tatsh-overlay's libretro-core eclass.
#
# The Makefile is chosen like the eclass does: Makefile.libretro or makefile.libretro when
# present, otherwise the default one. Cores built another way (CMake, for example) set
# libretro.build no and install their library with libretro.install_cores in destroot, or let
# the default destroot pick up ${libretro.cores} from ${libretro.build_dir}.
#
# Usage:
#   PortGroup               github 1.0
#   PortGroup               libretro_core 1.0
#   github.setup            libretro beetle-vb-libretro <commit>
#   name                    libretro-mednafen-vb
#   version                 20261012
#   libretro.cores          mednafen_vb     ;# default: ${name} without libretro-, - as _
#   libretro.build_dir      ${worksrcpath}  ;# where make runs and the library is written

options libretro.cores libretro.build_dir libretro.makefile libretro.dir
default libretro.cores      {[libretro::default_core]}
default libretro.build_dir  {${worksrcpath}}
default libretro.makefile   {[libretro::default_makefile]}
default libretro.dir        {${prefix}/lib/libretro}

categories          emulators games
maintainers         {gmail.com:audvare @Tatsh} openmaintainer
use_configure       no
default build.dir   {${libretro.build_dir}}
build.target
build.args-append   platform=osx \
                    CC=${configure.cc} \
                    CXX=${configure.cxx}
build.env-append    "CFLAGS=${configure.cflags} [get_canonical_archflags cc]" \
                    "CXXFLAGS=${configure.cxxflags} [get_canonical_archflags cxx]" \
                    "LDFLAGS=${configure.ldflags} [get_canonical_archflags ld]"

namespace eval libretro {}

proc libretro::default_core {} {
    global name
    set core [string map {- _} ${name}]
    regsub {^libretro_} ${core} {} core
    return ${core}
}

proc libretro::default_makefile {} {
    foreach f {Makefile.libretro makefile.libretro} {
        if {[file exists [option libretro.build_dir]/${f}]} {
            return ${f}
        }
    }
    return {}
}

proc libretro::install_cores {args} {
    global destroot
    set dir ${destroot}[option libretro.dir]
    xinstall -d ${dir}
    foreach f ${args} {
        xinstall -m 0755 ${f} ${dir}/
    }
}

pre-build {
    set mf [option libretro.makefile]
    if {${mf} ne ""} {
        build.args-append -f ${mf}
    }
}

destroot {
    set libs {}
    foreach core [option libretro.cores] {
        lappend libs [option libretro.build_dir]/${core}_libretro.dylib
    }
    libretro::install_cores {*}${libs}
}

livecheck.type      none
