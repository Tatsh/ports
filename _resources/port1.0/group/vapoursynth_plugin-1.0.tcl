# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# Common settings for VapourSynth plugins built against the vapoursynth port.
#
# VapourSynth R82 autoloads native plugins from the plugins directory inside its Python package,
# ${vapoursynth.plugindir}. Meson-based plugins that ask Python for that directory are pointed at
# the Python that vapoursynth is built for; anything a build system installs into
# ${prefix}/lib/vapoursynth is moved there after destroot.
#
# Python-only modules (havsfunc and so on) use ${vapoursynth.python_bin} and
# ${vapoursynth.site_packages}.

options vapoursynth.python_branch vapoursynth.python_bin vapoursynth.site_packages \
        vapoursynth.plugindir
# Keep in step with the python_branch of the vapoursynth port.
default vapoursynth.python_branch   3.14
default vapoursynth.python_bin      {${prefix}/bin/python${vapoursynth.python_branch}}
default vapoursynth.site_packages   {${frameworks_dir}/Python.framework/Versions/${vapoursynth.python_branch}/lib/python${vapoursynth.python_branch}/site-packages}
default vapoursynth.plugindir       {${vapoursynth.site_packages}/vapoursynth/plugins}

categories          multimedia
depends_build-append \
                    path:bin/pkg-config:pkgconfig
depends_lib-append  port:vapoursynth

post-patch {
    if {[file exists ${worksrcpath}/meson.build]} {
        reinplace -q -E "s|find_installation\\((pure: *false)?\\)|find_installation('${vapoursynth.python_bin}', pure: false)|" \
            ${worksrcpath}/meson.build
    }
}

post-destroot {
    # Meson asks a Python that may report ${prefix}/lib/pythonX.Y/site-packages as its install
    # directory rather than the framework's.
    set stray ${destroot}${prefix}/lib/python${vapoursynth.python_branch}/site-packages/vapoursynth/plugins
    if {[file isdirectory ${stray}]} {
        xinstall -d ${destroot}${vapoursynth.plugindir}
        foreach f [glob -nocomplain -directory ${stray} *] {
            file rename ${f} ${destroot}${vapoursynth.plugindir}/
        }
        file delete -force ${destroot}${prefix}/lib/python${vapoursynth.python_branch}
    }
    set libvs ${destroot}${prefix}/lib/vapoursynth
    if {[file isdirectory ${libvs}]} {
        xinstall -d ${destroot}${vapoursynth.plugindir}
        foreach f [glob -nocomplain -directory ${libvs} *.dylib *.so] {
            file rename ${f} ${destroot}${vapoursynth.plugindir}/
        }
        foreach f [glob -nocomplain -directory ${libvs} *.la] {
            file delete ${f}
        }
        if {[llength [glob -nocomplain -directory ${libvs} *]] == 0} {
            file delete ${libvs}
        }
    }
}

# Load the built plugin with VapourSynth itself: vapoursynth.test_namespace names the namespace
# it registers.
options vapoursynth.test_namespace
default vapoursynth.test_namespace {}
test.run            yes
test {
    if {${vapoursynth.test_namespace} ne ""} {
        set dirs {}
        fs-traverse f [list ${workpath}] {
            if {[file isfile ${f}] && [file extension ${f}] eq ".dylib"
                    && ![string match */destroot/* ${f}]} {
                set d [file dirname ${f}]
                if {${d} ni ${dirs}} {
                    lappend dirs ${d}
                }
            }
        }
        system -W ${workpath} "env VAPOURSYNTH_EXTRA_PLUGIN_PATH=[join ${dirs} :] ${vapoursynth.python_bin} -c \
            'import vapoursynth as vs; ns = getattr(vs.core, \"${vapoursynth.test_namespace}\"); print(ns)'"
    }
}
test.target
