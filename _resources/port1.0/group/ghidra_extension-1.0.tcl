# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# Build a Ghidra extension from source without Gradle and install it into the Ghidra
# installation of the ghidra port (<ghidra>/Ghidra/Extensions/<name>), where Ghidra loads it.
#
# The build compiles src/main/java (Java and Kotlin) against Ghidra's jars into
# lib/<name>.jar, builds the JavaHelp in src/main/help, compiles the SLEIGH specifications in
# data/languages, and stamps extension.properties with the installed Ghidra version.
#
# Usage:
#   PortGroup                   ghidra_extension 1.0
#   ghidra_extension.name       FooLoader       ;# directory and jar name (required)
#   ghidra_extension.scripts    foo.py bar.java ;# loose scripts to package as a module (optional)
#   ghidra_extension.classpath  ...             ;# extra jars to compile against (optional)

PortGroup           java 1.0

options ghidra_extension.name ghidra_extension.scripts ghidra_extension.classpath \
        ghidra_extension.home
default ghidra_extension.name       {}
default ghidra_extension.scripts    {}
default ghidra_extension.classpath  {}
default ghidra_extension.home       {[ghidra_extension::home]}

categories          devel java
platforms           any
supported_archs     noarch
use_configure       no

java.version        25+
java.fallback       openjdk25

depends_lib-append  port:ghidra
depends_build-append \
                    bin:unzip:unzip

namespace eval ghidra_extension {}

proc ghidra_extension::home {} {
    global prefix
    set homes [lsort -dictionary [glob -nocomplain -type d ${prefix}/share/java/ghidra-*]]
    if {[llength ${homes}] == 0} {
        return ${prefix}/share/java/ghidra
    }
    return [lindex ${homes} end]
}

proc ghidra_extension::property {key} {
    set fd [open [option ghidra_extension.home]/Ghidra/application.properties r]
    set value ""
    while {[gets ${fd} line] >= 0} {
        if {[string match "${key}=*" ${line}]} {
            set value [string range ${line} [expr {[string length ${key}] + 1}] end]
        }
    }
    close ${fd}
    return ${value}
}

proc ghidra_extension::classpath {} {
    global worksrcpath
    set jars {}
    fs-traverse f [list [option ghidra_extension.home]] {
        if {[string match */Ghidra/Extensions/* ${f}]} {
            continue
        }
        if {[file extension ${f}] eq ".jar"} {
            lappend jars ${f}
        }
    }
    foreach j [glob -nocomplain ${worksrcpath}/lib/*.jar] {
        lappend jars ${j}
    }
    foreach j [option ghidra_extension.classpath] {
        lappend jars ${j}
    }
    return [join ${jars} :]
}

proc ghidra_extension::java_env {} {
    global workpath
    return "env JAVA_HOME=[option java.home] XDG_CACHE_HOME=${workpath}/xdg/cache \
        XDG_CONFIG_HOME=${workpath}/xdg/config XDG_STATE_HOME=${workpath}/xdg/state \
        _JAVA_OPTIONS=-Djava.io.tmpdir=${workpath}/tmp"
}

post-patch {
    foreach cruft {.github gradle gradlew gradlew.bat gradle.properties build.gradle \
                   build.gradle.kts settings.gradle settings.gradle.kts certification.manifest} {
        file delete -force ${worksrcpath}/${cruft}
    }
    foreach z [glob -nocomplain ${worksrcpath}/lib/*-src.zip] {
        file delete ${z}
    }
    if {[llength [option ghidra_extension.scripts]]} {
        file mkdir ${worksrcpath}/ghidra_scripts
        foreach s [option ghidra_extension.scripts] {
            file rename ${worksrcpath}/${s} ${worksrcpath}/ghidra_scripts/
        }
        file mkdir ${worksrcpath}/data
        if {![file exists ${worksrcpath}/Module.manifest]} {
            close [open ${worksrcpath}/Module.manifest w]
        }
        if {![file exists ${worksrcpath}/extension.properties]} {
            set fd [open ${worksrcpath}/extension.properties w]
            puts ${fd} "name=[option ghidra_extension.name]\ndescription=[option description]\nauthor=\ncreatedOn=\nversion="
            close ${fd}
        }
    }
}

build {
    set name [option ghidra_extension.name]
    if {${name} eq ""} {
        return -code error "ghidra_extension.name must be set"
    }
    file mkdir ${workpath}/xdg/cache ${workpath}/xdg/config ${workpath}/xdg/state ${workpath}/tmp
    set jenv [ghidra_extension::java_env]
    set jbin [option java.home]/bin
    set release [ghidra_extension::property application.java.compiler]

    if {[file isdirectory ${worksrcpath}/src/main/java]} {
        set cp [ghidra_extension::classpath]
        set classes ${workpath}/classes
        file mkdir ${classes}
        set java_sources {}
        set kt_sources {}
        fs-traverse f [list ${worksrcpath}/src/main/java] {
            switch -- [file extension ${f}] {
                .java {lappend java_sources ${f}}
                .kt   {lappend kt_sources ${f}}
            }
        }
        if {[llength ${kt_sources}]} {
            system -W ${worksrcpath} "${jenv} ${prefix}/bin/kotlinc -classpath '${cp}' \
                -jvm-target ${release} -d ${classes} -nowarn src/main/java"
            file mkdir ${worksrcpath}/lib
            set stdlib [lindex [glob ${prefix}/share/kotlin/lib/kotlin-stdlib.jar \
                ${prefix}/share/java/kotlin*/lib/kotlin-stdlib.jar] 0]
            file copy -force ${stdlib} ${worksrcpath}/lib/
            set cp ${classes}:${stdlib}:${cp}
        }
        if {[llength ${java_sources}]} {
            set fd [open ${workpath}/java-sources.txt w]
            puts ${fd} [join ${java_sources} \n]
            close ${fd}
            system -W ${worksrcpath} "${jenv} ${jbin}/javac --release ${release} -d ${classes} \
                -encoding UTF-8 -proc:none -nowarn -classpath '${cp}' @${workpath}/java-sources.txt"
        }
        if {[file isdirectory ${worksrcpath}/src/main/resources]} {
            system "/bin/cp -R ${worksrcpath}/src/main/resources/. ${classes}/"
        }
        if {[file isdirectory ${worksrcpath}/src/main/help/help]} {
            system -W ${worksrcpath} "${jenv} ${jbin}/java -cp '${cp}' help.GHelpBuilder \
                -n ${name} -o ${classes}/help src/main/help/help"
            system "/bin/cp -R ${worksrcpath}/src/main/help/help/. ${classes}/help/"
            set javahelp {}
            fs-traverse f [list [option ghidra_extension.home]] {
                if {[string match javahelp-*.jar [file tail ${f}]]} {
                    set javahelp ${f}
                }
            }
            system -W ${worksrcpath}/src/main/help/help "${jenv} ${jbin}/java -cp ${javahelp} \
                com.sun.java.help.search.Indexer -db ${classes}/help/${name}_JavaHelpSearch topics"
        }
        file mkdir ${worksrcpath}/lib
        system -W ${worksrcpath} "${jenv} ${jbin}/jar --create --file lib/${name}.jar -C ${classes} ."
        file delete -force ${worksrcpath}/src
    }

    set version [ghidra_extension::property application.version]
    set props ${worksrcpath}/extension.properties
    if {[file exists ${props}]} {
        set fd [open ${props} r]
        fconfigure ${fd} -translation binary
        set text [read ${fd}]
        close ${fd}
        regsub -all -line {^version=.*$} ${text} "version=${version}" text
        regsub -all -line {^name=.*$} ${text} "name=${name}" text
        set fd [open ${props} w]
        fconfigure ${fd} -translation binary
        puts -nonewline ${fd} ${text}
        close ${fd}
    }

    if {[llength [glob -nocomplain ${worksrcpath}/data/languages/*.slaspec]]} {
        system -W ${worksrcpath} "${jenv} /bin/bash [option ghidra_extension.home]/support/sleigh \
            -a data/languages"
    }
}

destroot {
    set dest ${destroot}[option ghidra_extension.home]/Ghidra/Extensions/[option ghidra_extension.name]
    xinstall -d ${dest}
    foreach f [glob -nocomplain -directory ${worksrcpath} *] {
        copy ${f} ${dest}/
    }
}

livecheck.type      none
