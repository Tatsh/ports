# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# Install mpv user scripts and shaders into mpv's system configuration directory
# (${prefix}/etc/mpv), where mpv loads scripts automatically and resolves ~~/ paths.
#
# Usage:
#   PortGroup           mpv_plugin 1.0
#   mpv_plugin.files    foo.lua                 ;# scripts or script directories, relative to worksrcpath
#   mpv_plugin.opts     script-opts/foo.conf    ;# optional script-opts files
#   mpv_plugin.shaders  foo.glsl                ;# shaders (use instead of, or with, files)
#   mpv_plugin.docs     README.md               ;# optional documentation
#   mpv_plugin.dirname  foo                     ;# install files into scripts/foo/ (for main.lua scripts)

options mpv_plugin.files mpv_plugin.opts mpv_plugin.shaders mpv_plugin.docs mpv_plugin.dirname
default mpv_plugin.dirname  {}
default mpv_plugin.files    {}
default mpv_plugin.opts     {}
default mpv_plugin.shaders  {}
default mpv_plugin.docs     {}

categories          multimedia
platforms           any
supported_archs     noarch
use_configure       no
depends_run-append  path:bin/mpv:mpv

build {}

destroot {
    set confdir ${destroot}${prefix}/etc/mpv
    if {[llength ${mpv_plugin.files}]} {
        set sdir ${confdir}/scripts
        if {${mpv_plugin.dirname} ne ""} {
            set sdir ${sdir}/${mpv_plugin.dirname}
        }
        xinstall -d ${sdir}
        foreach f ${mpv_plugin.files} {
            copy ${worksrcpath}/${f} ${sdir}/
        }
    }
    if {[llength ${mpv_plugin.opts}]} {
        xinstall -d ${confdir}/script-opts
        foreach f ${mpv_plugin.opts} {
            xinstall -m 0644 ${worksrcpath}/${f} ${confdir}/script-opts/
        }
    }
    if {[llength ${mpv_plugin.shaders}]} {
        xinstall -d ${confdir}/shaders
        foreach f ${mpv_plugin.shaders} {
            if {[file pathtype ${f}] ne "absolute"} {
                set f ${worksrcpath}/${f}
            }
            xinstall -m 0644 ${f} ${confdir}/shaders/
        }
    }
    if {[llength ${mpv_plugin.docs}]} {
        xinstall -d ${destroot}${prefix}/share/doc/${subport}
        foreach f ${mpv_plugin.docs} {
            xinstall -m 0644 ${worksrcpath}/${f} ${destroot}${prefix}/share/doc/${subport}/
        }
    }
}

livecheck.type      none
