#!/bin/sh
SHIP_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/spaghettikart"
export SHIP_HOME
mkdir -p "${SHIP_HOME}" || exit 1
cd "${SHIP_HOME}" || exit 1
exec "@PREFIX@/libexec/spaghettikart/Spaghettify" "$@"
