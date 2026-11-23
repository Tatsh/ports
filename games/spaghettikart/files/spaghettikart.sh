#!/bin/sh
SHIP_HOME="${HOME}/Library/Application Support/spaghettikart"
export SHIP_HOME
mkdir -p "${SHIP_HOME}" || exit 1
cd "${SHIP_HOME}" || exit 1
exec "@PREFIX@/libexec/spaghettikart/Spaghettify" "$@"
