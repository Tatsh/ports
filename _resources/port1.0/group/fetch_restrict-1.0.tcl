# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# Files that cannot be downloaded automatically: installers behind a login, game ROMs and game
# files from the user's own copy. This is the MacPorts counterpart of Gentoo's RESTRICT="fetch"
# with pkg_nofetch.
#
# Each restricted file is listed with a digest that identifies the expected copy (ROM hashes are
# often published only as SHA-1 or SHA-512, so this does not go through the checksums option).
# Before fetching, every restricted file must already be in ${fetch_restrict.dir}, and must match
# its digest; otherwise the port stops with the instructions and the exact path for each file. The
# other distfiles are downloaded and checked as usual. Ports that use this are not distributable as
# binary archives.
#
# Usage:
#   PortGroup               fetch_restrict 1.0
#   fetch_restrict.files    {smw.sfc sha512 c9207d...}      ;# name, md5|sha1|sha256|sha512, digest
#   fetch_restrict.instructions {Copy your Super Mario World (US) ROM ...}
#   post-extract { file copy [fetch_restrict::path smw.sfc] ${worksrcpath}/ }

options fetch_restrict.files fetch_restrict.instructions fetch_restrict.dir
default fetch_restrict.files        {}
default fetch_restrict.instructions {}
default fetch_restrict.dir          {${distpath}}

license-append      Restrictive

namespace eval fetch_restrict {}

proc fetch_restrict::path {name} {
    return [option fetch_restrict.dir]/${name}
}

proc fetch_restrict::digest {type file} {
    set out [exec /usr/bin/openssl dgst -${type} -r ${file}]
    return [string tolower [lindex [split ${out}] 0]]
}

proc fetch_restrict::check {} {
    set problems {}
    foreach entry [option fetch_restrict.files] {
        lassign ${entry} name type want
        set f [fetch_restrict::path ${name}]
        if {![file exists ${f}]} {
            lappend problems "missing: ${f}"
            continue
        }
        set got [fetch_restrict::digest ${type} ${f}]
        if {${got} ne [string tolower ${want}]} {
            lappend problems "wrong file: ${f} has ${type} ${got}, expected ${want}"
        }
    }
    return ${problems}
}

pre-fetch {
    set problems [fetch_restrict::check]
    if {[llength ${problems}]} {
        ui_error "${subport} needs files that cannot be downloaded automatically."
        foreach line [split [string trim [join [option fetch_restrict.instructions]]] \n] {
            ui_error [string trim ${line}]
        }
        foreach p ${problems} {
            ui_error "  ${p}"
        }
        set dir [option fetch_restrict.dir]
        ui_error "Copy the files into ${dir}, for example:"
        ui_error "  sudo mkdir -p ${dir} && sudo cp /path/to/file ${dir}/"
        return -code error "fetch-restricted files are missing or do not match"
    }
}
